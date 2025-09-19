;; Athlete Reputation & Rating System
;; Enables sponsors to rate athletes and build transparent reputation profiles

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_RATING (err u201))
(define-constant ERR_ALREADY_RATED (err u202))
(define-constant ERR_MILESTONE_NOT_VERIFIED (err u203))
(define-constant ERR_NOT_FOUND (err u204))

;; Data variables
(define-data-var next-rating-id uint u1)

;; Individual ratings given by sponsors to athletes
(define-map athlete-ratings
  { sponsor: principal, athlete: principal, milestone-id: uint }
  {
    rating: uint,
    feedback: (optional (string-ascii 512)),
    created-at: uint,
    rating-id: uint
  }
)

;; Aggregate reputation data for each athlete
(define-map athlete-reputation
  principal
  {
    total-ratings: uint,
    rating-sum: uint,
    average-rating: uint,
    last-updated: uint
  }
)

;; Rating history for analytics
(define-map rating-history
  uint
  {
    sponsor: principal,
    athlete: principal,
    milestone-id: uint,
    rating: uint,
    created-at: uint
  }
)

;; Track which milestones have been rated
(define-map milestone-rated
  { milestone-id: uint, sponsor: principal }
  bool
)

;; Rate an athlete (1-5 stars) - only after milestone verification
(define-public (rate-athlete (athlete principal) (milestone-id uint) (rating uint) (feedback (optional (string-ascii 512))))
  (let (
    (rating-id (var-get next-rating-id))
    (rating-key { sponsor: tx-sender, athlete: athlete, milestone-id: milestone-id })
    (milestone-rating-key { milestone-id: milestone-id, sponsor: tx-sender })
  )
    ;; Validate rating bounds (1-5)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    
    ;; Check if already rated this milestone
    (asserts! (is-none (map-get? milestone-rated milestone-rating-key)) ERR_ALREADY_RATED)
    
    ;; Store individual rating
    (map-set athlete-ratings rating-key {
      rating: rating,
      feedback: feedback,
      created-at: stacks-block-height,
      rating-id: rating-id
    })
    
    ;; Store in rating history
    (map-set rating-history rating-id {
      sponsor: tx-sender,
      athlete: athlete,
      milestone-id: milestone-id,
      rating: rating,
      created-at: stacks-block-height
    })
    
    ;; Mark milestone as rated
    (map-set milestone-rated milestone-rating-key true)
    
    ;; Update aggregate reputation
    (unwrap! (update-reputation athlete rating) (err u999))
    
    ;; Increment rating ID
    (var-set next-rating-id (+ rating-id u1))
    
    (ok rating-id)
  )
)

;; Update aggregate reputation for an athlete
(define-private (update-reputation (athlete principal) (new-rating uint))
  (let (
    (current-rep (default-to 
      { total-ratings: u0, rating-sum: u0, average-rating: u0, last-updated: u0 }
      (map-get? athlete-reputation athlete)
    ))
    (new-total (+ (get total-ratings current-rep) u1))
    (new-sum (+ (get rating-sum current-rep) new-rating))
    (new-average (/ new-sum new-total))
  )
    (map-set athlete-reputation athlete {
      total-ratings: new-total,
      rating-sum: new-sum,
      average-rating: new-average,
      last-updated: stacks-block-height
    })
    (ok true)
  )
)

;; Get individual rating details
(define-read-only (get-rating (sponsor principal) (athlete principal) (milestone-id uint))
  (map-get? athlete-ratings { sponsor: sponsor, athlete: athlete, milestone-id: milestone-id })
)

;; Get athlete's aggregate reputation
(define-read-only (get-athlete-reputation (athlete principal))
  (map-get? athlete-reputation athlete)
)

;; Get rating from history by ID
(define-read-only (get-rating-by-id (rating-id uint))
  (map-get? rating-history rating-id)
)

;; Check if milestone has been rated by sponsor
(define-read-only (is-milestone-rated (milestone-id uint) (sponsor principal))
  (default-to false (map-get? milestone-rated { milestone-id: milestone-id, sponsor: sponsor }))
)

;; Get reputation tier (Bronze/Silver/Gold/Platinum)
(define-read-only (get-reputation-tier (athlete principal))
  (let ((reputation (map-get? athlete-reputation athlete)))
    (match reputation
      rep-data 
        (if (< (get total-ratings rep-data) u5) "Unranked"
          (if (>= (get average-rating rep-data) u450) "Platinum"
            (if (>= (get average-rating rep-data) u400) "Gold"
              (if (>= (get average-rating rep-data) u350) "Silver" "Bronze"))))
      "Unranked")))

;; Get reputation summary with tier
(define-read-only (get-reputation-summary (athlete principal))
  (let ((reputation (map-get? athlete-reputation athlete))
        (tier (get-reputation-tier athlete)))
    (match reputation
      rep-data { total-ratings: (get total-ratings rep-data), average-rating: (get average-rating rep-data), tier: tier, last-updated: (get last-updated rep-data) }
      { total-ratings: u0, average-rating: u0, tier: tier, last-updated: u0 })))

;; Check if athlete meets minimum reputation threshold
(define-read-only (meets-reputation-threshold (athlete principal) (min-rating uint) (min-count uint))
  (let (
    (reputation (map-get? athlete-reputation athlete))
  )
    (match reputation
      rep-data 
        (and 
          (>= (get average-rating rep-data) min-rating)
          (>= (get total-ratings rep-data) min-count)
        )
      false
    )
  )
)

;; Get current rating ID counter
(define-read-only (get-current-rating-id)
  (var-get next-rating-id)
)