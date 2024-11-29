(define-constant ERR_ALREADY_ADOPTED u100)
(define-constant ERR_INVALID_ANIMAL u101)

(define-map adopted-animals principal (string-ascii 20))

(define-constant allowed-animals (list
    "Dog"
    "Cat"
    "Rabbit"
    "Parrot"
))

(define-private (check-animal (current-animal (string-ascii 20)) (state {animal: (string-ascii 20), found: bool}))
    (if (get found state)
        state
        {animal: (get animal state), found: (is-eq current-animal (get animal state))}
    )
)

(define-read-only (is-valid-animal (animal (string-ascii 20)))
    (get found (fold check-animal allowed-animals {animal: animal, found: false}))
)

(define-read-only (get-adopted-animal (adopter principal))
    (match (map-get? adopted-animals adopter)
        animal (ok animal)
        (err ERR_INVALID_ANIMAL)
    )
)

(define-public (adopt-animal (animal (string-ascii 20)))
    (let 
        (
            (is-valid (is-valid-animal animal))
            (current-adoption (map-get? adopted-animals tx-sender))
        )
        (asserts! is-valid (err ERR_INVALID_ANIMAL))
        (asserts! (is-none current-adoption) (err ERR_ALREADY_ADOPTED))
        (ok (map-insert adopted-animals tx-sender animal))
    )
)