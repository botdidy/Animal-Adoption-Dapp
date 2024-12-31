;; Constants
(define-constant ERR_ALREADY_ADOPTED u100)
(define-constant ERR_INVALID_ANIMAL u101)
(define-constant ERR_NOT_ADOPTED u102)
(define-constant ERR_UNAUTHORIZED u103)
(define-constant ERR_INVALID_AGE u104)
(define-constant ERR_INVALID_HEALTH_STATUS u105)
(define-constant MAX_ADOPTION_LIMIT u3)
(define-constant MAX_AGE u30)
(define-constant MIN_AGE u0)

;; Data Maps
(define-map adopted-animals principal (string-ascii 20))
(define-map adoption-count principal uint)

;; List of allowed animals
(define-constant allowed-animals (list
    "Dog"
    "Cat"
    "Rabbit"
    "Parrot"
    "Hamster"
    "Fish"
))

;; List of valid health statuses
(define-constant valid-health-statuses (list
    "Healthy"
    "Sick"
    "Critical"
))

;; Private Functions
(define-private (check-animal (current-animal (string-ascii 20)) (state {animal: (string-ascii 20), found: bool}))
    (if (get found state)
        state
        {animal: (get animal state), found: (is-eq current-animal (get animal state))}
    )
)

(define-private (check-health-status (status (string-ascii 10)) (state {current: (string-ascii 10), found: bool}))
    (if (get found state)
        state
        {current: status, found: (is-eq status (get current state))}
    )
)

(define-private (validate-age (age uint))
    (and 
        (>= age MIN_AGE)
        (<= age MAX_AGE)
    )
)

;; Read-only Functions
(define-read-only (is-valid-animal (animal (string-ascii 20)))
    (get found (fold check-animal allowed-animals {animal: animal, found: false}))
)

(define-read-only (is-valid-health-status (status (string-ascii 10)))
    (get found (fold check-health-status valid-health-statuses {current: status, found: false}))
)

(define-read-only (get-adopted-animal (adopter principal))
    (match (map-get? adopted-animals adopter)
        animal (ok animal)
        (err ERR_NOT_ADOPTED)
    )
)

(define-read-only (get-adoption-count (adopter principal))
    (default-to u0 (map-get? adoption-count adopter))
)

(define-read-only (can-adopt (adopter principal))
    (< (get-adoption-count adopter) MAX_ADOPTION_LIMIT)
)

;; Public Functions
(define-public (adopt-animal (animal (string-ascii 20)))
    (let 
        (
            (is-valid (is-valid-animal animal))
            (current-count (get-adoption-count tx-sender))
        )
        (asserts! is-valid (err ERR_INVALID_ANIMAL))
        (asserts! (can-adopt tx-sender) (err ERR_ALREADY_ADOPTED))
        ;; Validate input before mapping
        (match (map-get? adopted-animals tx-sender) 
            prev-adoption (err ERR_ALREADY_ADOPTED)
            (begin
                (map-set adopted-animals tx-sender animal)
                (map-set adoption-count tx-sender (+ current-count u1))
                (ok true)
            )
        )
    )
)

(define-public (change-animal (new-animal (string-ascii 20)))
    (let
        (
            (is-valid (is-valid-animal new-animal))
            (current-adoption (map-get? adopted-animals tx-sender))
        )
        (asserts! is-valid (err ERR_INVALID_ANIMAL))
        (asserts! (is-some current-adoption) (err ERR_NOT_ADOPTED))
        ;; Additional validation before changing
        (match current-adoption
            prev-animal 
                (if (is-eq prev-animal new-animal)
                    (err ERR_ALREADY_ADOPTED)
                    (ok (map-set adopted-animals tx-sender new-animal))
                )
            (err ERR_NOT_ADOPTED)
        )
    )
)

(define-public (release-animal)
    (let
        (
            (current-adoption (map-get? adopted-animals tx-sender))
            (current-count (get-adoption-count tx-sender))
        )
        (asserts! (is-some current-adoption) (err ERR_NOT_ADOPTED))
        ;; Additional validation before release
        (match current-adoption
            animal 
                (begin
                    (map-delete adopted-animals tx-sender)
                    (map-set adoption-count tx-sender (- current-count u1))
                    (ok true)
                )
            (err ERR_NOT_ADOPTED)
        )
    )
)
