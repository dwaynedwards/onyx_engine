package onyx

EventType :: enum {
    EVENT_TYPE_UNUSER,
}

Event :: struct #raw_union {
    type: EventType,
}