# Generated by Django 4.0.2 on 2022-02-07 19:52

from decimal import Decimal
import django.core.validators
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='ServiceOffer',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated at')),
                ('barber_name', models.CharField(max_length=100, validators=[django.core.validators.MinLengthValidator(2)], verbose_name='Barber Name')),
                ('city', models.CharField(max_length=100, validators=[django.core.validators.MinLengthValidator(2)], verbose_name='City')),
                ('address', models.CharField(max_length=100, validators=[django.core.validators.MinLengthValidator(2)], verbose_name='Address')),
                ('description', models.CharField(max_length=400, verbose_name='Description')),
                ('price', models.DecimalField(decimal_places=2, max_digits=9, validators=[django.core.validators.MinValueValidator(Decimal('0.01'))], verbose_name='Price')),
                ('image', models.ImageField(blank=True, upload_to='barber/service_offer', verbose_name='Barber Image')),
                ('specialization', models.CharField(choices=[('MEN', 'Men'), ('WOMEN', 'Women'), ('WOMEN_AND_MEN', 'Women & Men'), ('NOT_SPECIFIED', 'Not Specified')], max_length=13, verbose_name='Specialization')),
                ('status', models.CharField(choices=[('ACTIVE', 'Active'), ('HIDDEN', 'Hidden'), ('CLOSED', 'Closed')], max_length=6, verbose_name='Status')),
                ('open_hours', models.CharField(choices=[('FROM_8AM_TO_4PM', '8AM-4PM'), ('FROM_9AM_TO_5PM', '9AM-5PM'), ('FROM_10AM_TO_6PM', '10AM-6PM'), ('FROM_11AM_TO_7PM', '11AM-7PM'), ('FROM_12AM_TO_8PM', '12PM-8PM')], max_length=16, verbose_name='Open Hours')),
                ('working_days', models.CharField(choices=[('MONDAY_FRIDAY', 'Monday-Friday'), ('MONDAY_SATURDAY', 'Monday-Saturday'), ('MONDAY_SUNDAY', 'Monday-Sunday')], max_length=15, verbose_name='Working Days')),
            ],
        ),
        migrations.CreateModel(
            name='ServiceUnavailability',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated at')),
                ('start_date', models.DateField(verbose_name='Start Date')),
                ('end_date', models.DateField(verbose_name='End Date')),
                ('reason', models.CharField(max_length=400, verbose_name='Reason')),
                ('service_offer', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, to='barber.serviceoffer')),
            ],
        ),
    ]