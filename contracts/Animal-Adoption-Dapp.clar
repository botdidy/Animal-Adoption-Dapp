;; Constants
(define-constant ERR_ALREADY_ADOPTED u100)
(define-constant ERR_INVALID_ANIMAL u101)
(define-constant ERR_NOT_ADOPTED u102)
(define-constant ERR_UNAUTHORIZED u103)
(define-constant MAX_ADOPTION_LIMIT u3)

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

;; Private Functions
(define-private (check-animal (current-animal (string-ascii 20)) (state {animal: (string-ascii 20), found: bool}))
    (if (get found state)
        state
        {animal: (get animal state), found: (is-eq current-animal (get animal state))}
    )
)

;; Read-only Functions
(define-read-only (is-valid-animal (animal (string-ascii 20)))
    (get found (fold check-animal allowed-animals {animal: animal, found: false}))
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
        (map-set adopted-animals tx-sender animal)
        (map-set adoption-count tx-sender (+ current-count u1))
        (ok true)
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
        (ok (map-set adopted-animals tx-sender new-animal))
    )
)

(define-public (release-animal)
    (let
        (
            (current-adoption (map-get? adopted-animals tx-sender))
            (current-count (get-adoption-count tx-sender))
        )
        (asserts! (is-some current-adoption) (err ERR_NOT_ADOPTED))
        (map-delete adopted-animals tx-sender)
        (map-set adoption-count tx-sender (- current-count u1))
        (ok true)
    )
)