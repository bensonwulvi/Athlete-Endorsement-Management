;; Performance Milestone Tracker Contract
;; Manages athlete performance milestones and endorsement deal tracking

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_MILESTONE_COMPLETED (err u103))
(define-constant ERR_DEADLINE_PASSED (err u104))
(define-constant ERR_INVALID_PARAMS (err u105))

;; Data variables
(define-data-var next-milestone-id uint u1)

;; Core milestone data
(define-map milestones
  uint
  {
    athlete: principal,
    sponsor: principal,
    description: (string-ascii 256),
    target-value: uint,
    reward-amount: uint,
    deadline: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

;; Milestone achievements
(define-map milestone-achievements
  uint
  {
    achieved-value: uint,
    completion-notes: (optional (string-ascii 512)),
    completed-at: uint,
    verified-at: (optional uint),
    verified: bool
  }
)

;; Athlete milestone tracking
(define-map athlete-milestones
  { athlete: principal, milestone-id: uint }
  bool
)

;; Sponsor milestone tracking  
(define-map sponsor-milestones
  { sponsor: principal, milestone-id: uint }
  bool
)

;; Create milestone
(define-public (create-milestone (athlete principal) (description (string-ascii 256)) (target-value uint) (reward-amount uint) (deadline uint))
  (let ((milestone-id (var-get next-milestone-id)))
    (asserts! (> deadline stacks-block-height) ERR_DEADLINE_PASSED)
    (asserts! (> target-value u0) ERR_INVALID_PARAMS)
    (asserts! (> reward-amount u0) ERR_INVALID_PARAMS)
    
    ;; Store milestone
    (map-set milestones milestone-id {
      athlete: athlete,
      sponsor: tx-sender,
      description: description,
      target-value: target-value,
      reward-amount: reward-amount,
      deadline: deadline,
      status: "pending",
      created-at: stacks-block-height
    })
    
    ;; Track for athlete and sponsor
    (map-set athlete-milestones { athlete: athlete, milestone-id: milestone-id } true)
    (map-set sponsor-milestones { sponsor: tx-sender, milestone-id: milestone-id } true)
    
    ;; Increment next ID
    (var-set next-milestone-id (+ milestone-id u1))
    (ok milestone-id)
  )
)

;; Complete milestone
(define-public (complete-milestone (milestone-id uint) (achieved-value uint) (notes (optional (string-ascii 512))))
  (let ((milestone (unwrap! (map-get? milestones milestone-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get athlete milestone)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status milestone) "pending") ERR_MILESTONE_COMPLETED)
    (asserts! (<= stacks-block-height (get deadline milestone)) ERR_DEADLINE_PASSED)
    
    ;; Update milestone status
    (map-set milestones milestone-id (merge milestone { status: "completed" }))
    
    ;; Record achievement
    (map-set milestone-achievements milestone-id {
      achieved-value: achieved-value,
      completion-notes: notes,
      completed-at: stacks-block-height,
      verified-at: none,
      verified: false
    })
    
    (ok true)
  )
)

;; Verify milestone
(define-public (verify-milestone (milestone-id uint))
  (let ((milestone (unwrap! (map-get? milestones milestone-id) ERR_NOT_FOUND))
        (achievement (unwrap! (map-get? milestone-achievements milestone-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get sponsor milestone)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status milestone) "completed") ERR_NOT_FOUND)
    
    ;; Update milestone and achievement
    (map-set milestones milestone-id (merge milestone { status: "verified" }))
    (map-set milestone-achievements milestone-id 
      (merge achievement { 
        verified: true, 
        verified-at: (some stacks-block-height) 
      })
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones milestone-id)
)

(define-read-only (get-milestone-achievement (milestone-id uint))
  (map-get? milestone-achievements milestone-id)
)

(define-read-only (milestone-exists (milestone-id uint))
  (is-some (map-get? milestones milestone-id))
)

;; Helper function to check if athlete has milestone
(define-read-only (athlete-has-milestone (athlete principal) (milestone-id uint))
  (default-to false (map-get? athlete-milestones { athlete: athlete, milestone-id: milestone-id }))
)

;; Helper function to check if sponsor has milestone
(define-read-only (sponsor-has-milestone (sponsor principal) (milestone-id uint))
  (default-to false (map-get? sponsor-milestones { sponsor: sponsor, milestone-id: milestone-id }))
)