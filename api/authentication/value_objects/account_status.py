import enum


class AccountStatus(enum.Enum):
    ACTIVE = 'ACTIVE'
    CLOSED = 'CLOSED'  # Personal data is not deleted
    DELETED = 'DELETED'
    UNDER_VERIFICATION = 'UNDER_VERIFICATION'
