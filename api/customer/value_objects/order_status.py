import enum


class ServiceOrderStatus(enum.Enum):
    NEW = 'New'
    CONFIRMED = 'Confirmed'
    CLOSED = 'Closed'
