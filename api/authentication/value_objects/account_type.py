import enum


class AccountType(enum.Enum):
    ADMIN = 'ADMIN'
    BARBER = 'BARBER'
    CUSTOMER = 'CUSTOMER'

    @classmethod
    def can_login_to_admin_panel(cls, account_type: 'AccountType') -> bool:
        return account_type in {cls.ADMIN, cls.BARBER}
