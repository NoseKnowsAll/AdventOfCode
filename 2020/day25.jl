" Apply one iteration of the cryptographic transformation "
function transform_once(value, subject, PRIME=20201227)
    return mod(value*subject, PRIME)
end
" Apply the full cryptographic transformation "
function transform(subject, loop_size)
    value = 1
    for i = 1:loop_size
        value = transform_once(value, subject)
    end
    return value
end
" Determine the loop size for either the card or door, whichever comes first "
function decrypt_size(card_key, door_key)
    found_card = false
    found_door = false
    value = 1
    loop_size = 1
    while !(found_card || found_door)
        value = transform_once(value, 7)
        if value == card_key
            found_card = true
            break
        elseif value == door_key
            found_door = true
            break
        end
        loop_size += 1
    end
    return found_card, loop_size
end
" Solve Day 25-1 "
function encryption_key(card_key=7573546,door_key=17786549)
    found_card, loop_size = decrypt_size(card_key, door_key)
    # Complete the handshake to compute the actual encryption key
    if found_card
        return transform(door_key, loop_size)
    else
        return transform(card_key, loop_size)
    end
end
