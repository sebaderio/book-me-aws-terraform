import logging
from typing import List, Optional, Union

import sendgrid  # type: ignore

from core.config import utils

logger = logging.getLogger('celery')


def send_email(message: sendgrid.Mail) -> Union[int, str]:
    '''Send email using Sendgrid SDK.
    Args:
        message: sendgrid.Mail object instance
    Returns:
        response: int | str
        int: SDK response status code
        str: Exception in case of internal Sendgrid SDK error
    '''

    sendgrid_api_key = utils.get_env_value('SENDGRID_API_KEY')
    try:
        sendgrid_client = sendgrid.SendGridAPIClient(sendgrid_api_key)
        return sendgrid_client.send(message).status_code
    except Exception as exc:  # pylint: disable=broad-except
        logger.exception(exc)
        return str(exc)


def generate_message(
    to_emails: Union[str, List[str]], template_id: str, template_data: Optional[dict] = None
) -> sendgrid.Mail:
    '''Generate message to be sent with Sendgrid SDK.
    Args:
        to_emails: One or list of email addresses that message should be sent to
        template_id: Email template id stored in the associated Sendgrid account
        template_data: Dict with customizable fields data for a template in format key(str):value(str)
    Returns:
        message: sendgrid.Mail object
    '''
    sendgrid_sender_email = utils.get_env_value('SENDGRID_SENDER_EMAIL')
    message = sendgrid.Mail(from_email=sendgrid_sender_email, to_emails=to_emails)
    message.dynamic_template_data = template_data
    message.template_id = template_id
    return message
