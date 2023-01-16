const parseDateTimeToDateString = (dateTime) =>
  `${dateTime.getFullYear()}-${("0" + (dateTime.getMonth() + 1)).slice(-2)}-${(
    "0" + dateTime.getDate()
  ).slice(-2)}`;

export default parseDateTimeToDateString;
