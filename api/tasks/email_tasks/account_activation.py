import socket
from typing import List, Union

from core.config import utils
from tasks import celery
from tasks.email_tasks import email_sending_core

MAX_ATTEMPTS_COUNT = 10


@celery.app.task(autoretry_for=(socket.error,), retry_kwargs={'max_retries': MAX_ATTEMPTS_COUNT})
def send_email_with_account_activation_link(
    to_emails: Union[str, List[str]], template_data: dict
) -> Union[int, str]:
    '''Send emails with account activation link.
    Args:
        to_emails: One or list of email addresses that message should be sent to
        template_data: Dict with customizable fields data for a template
            activation_link: str
            user_email: str
            user_name: str (suggested name + surname)
    '''
    template_id = utils.get_env_value('SENDGRID_ACCOUNT_ACTIVATION_TEMPLATE_ID')
    message = email_sending_core.generate_message(to_emails, template_id, template_data)
    return email_sending_core.send_email(message)
