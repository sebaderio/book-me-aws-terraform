import enum
import functools
import typing
from typing import Callable

from django.utils.translation import gettext_lazy as __


def enum_to_char_field_args(enum_object: typing.Type[enum.Enum]) -> typing.Dict:  # type: ignore
    '''Convert enum to char field when defining a model.'''
    return {
        'max_length': max(len(constant.name) for constant in enum_object),
        'choices': [(constant.name, constant.value) for constant in enum_object],
    }


def enum_to_char_field_args_translated(enum_object: typing.Type[enum.Enum]) -> typing.Dict:  # type: ignore
    '''Convert enum to char field and translate field value.'''
    return {
        'max_length': max(len(constant.name) for constant in enum_object),
        'choices': [(constant.name, __(constant.value)) for constant in enum_object],
    }


def flat_dictionary(dictionary: typing.Dict, parent_key: str = '', sep: str = '') -> typing.Dict:
    '''https://stackoverflow.com/questions/6027558/flatten-nested-dictionaries-compressing-keys'''
    items: typing.List[typing.Tuple[str, typing.Any]] = []
    for key, value in dictionary.items():
        new_key_name = f'{parent_key}{sep}{key}'
        if isinstance(value, dict):
            items.extend(flat_dictionary(value, new_key_name, '_').items())
        else:
            items.append((new_key_name, value))
    return dict(items)


def prevent_signal_recursion(func: Callable) -> Callable:
    @functools.wraps(func)
    def no_recursion(sender, instance=None, **kwargs):  # type:ignore
        if not instance or hasattr(instance, '_dirty'):
            return
        func(sender, instance=instance, **kwargs)
        instance._dirty = True  # pylint: disable=protected-access
        instance.save()

    return no_recursion
