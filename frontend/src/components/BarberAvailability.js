import { useContext, useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import AdapterDateFns from "@mui/lab/AdapterDateFns";
import Box from "@mui/material/Box";
import DesktopDatePicker from "@mui/lab/DesktopDatePicker";
import Grid from "@mui/material/Grid";
import LocalizationProvider from "@mui/lab/LocalizationProvider";
import TextField from "@mui/material/TextField";
import ModalBase from "./modals/ModalBase";
import BookOrCancelBarberServiceItem from "./BookOrCancelBarberServiceItem";
import TextInputTwoButtonsModalContent from "./modals/TextInputTwoButtonsModalContent";
import TextOneButtonModalContent from "./modals/TextOneButtonModalContent";
import TextTwoButtonsModalContent from "./modals/TextTwoButtonsModalContent";
import AuthContext from "../context/AuthContext";
import useAxios from "../utils/useAxios";
import parseDateTimeToDateString from "../utils/parseDateTimeToDateString";
import {
  openHoursToHoursRangeParser,
  serviceTimesGenerator,
} from "../utils/serviceTimesGenerator";

const getMinDate = ({ date, openHours }) => {
  const dateToday = new Date();
  if (
    !(
      date.getDate() === dateToday.getDate() &&
      date.getMonth() === dateToday.getMonth() &&
      date.getFullYear() === dateToday.getFullYear()
    )
  ) {
    return date;
  }
  const openHoursRange = openHoursToHoursRangeParser(openHours);
  if (
    dateToday.getHours() >= openHoursRange.endHour ||
    (dateToday.getHours() === openHoursRange.endHour &&
      dateToday.getMinutes() >= 30)
  ) {
    dateToday.setDate(dateToday.getDate() + 1);
  }
  return dateToday;
};

const isAlnumValidator = (val) => {
  if (val.match(/^[a-z0-9]+$/i)) {
    return "";
  }
  return "Token should be alphanumeric.";
};

const lengthValidator = (val) => {
  if (val.length === 8) {
    return "";
  }
  return "Token should be 8 length.";
};

export default function BarberAvailability(props) {
  const { offer } = props;
  const { user } = useContext(AuthContext);
  const [date, setDate] = useState(
    getMinDate({ date: new Date(), openHours: offer.open_hours })
  );
  const [generalModalOpen, setGeneralModalOpen] = useState(false);
  const [generalModalProps, setGeneralModalProps] = useState(null);
  const [finalWordsModalOpen, setFinalWordsModalOpen] = useState(false);
  const [finalWordsModalProps, setFinalWordsModalProps] = useState(null);
  const [inputModalOpen, setInputModalOpen] = useState(false);
  const [inputModalProps, setInputModalProps] = useState(null);
  const [serviceTimesInfo, setServiceTimesInfo] = useState([]);
  const api = useAxios();
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    setServiceTimesInfo(
      serviceTimesGenerator({
        date: parseDateTimeToDateString(date),
        ...props,
      })
    );
  }, [date, props]);

  const bookServiceHandler = ({ offerId, dateTime }) => {
    if (!user) {
      setGeneralModalProps(redirectToLoginModalProps);
    } else {
      setGeneralModalProps({
        ...doYouWantToBookModalProps,
        itemData: { dateTime, offerId },
      });
    }
    setGeneralModalOpen(true);
  };

  const cancelServiceHandler = () => {
    if (!user) {
      setGeneralModalProps(redirectToLoginModalProps);
      setGeneralModalOpen(true);
    } else {
      setInputModalProps(cancelServiceModalProps);
      setInputModalOpen(true);
    }
  };

  const cancelServiceModalProps = {
    contentText: "Enter token to cancel your reservation.",
    headerText: null,
    inputValidators: [lengthValidator, isAlnumValidator],
    leftButtonOnClick: () => {
      setInputModalOpen(false);
    },
    leftButtonText: "BACK",
    rightButtonOnClick: (token) => {
      api
        .delete("/customer/service_order/", { data: { token } })
        .then(() => {
          setFinalWordsModalProps(finalWordsCancelledModalProps);
          setInputModalOpen(false);
          setFinalWordsModalOpen(true);
        })
        .catch((error) => {
          let failedModalProps = failedCancellationModalProps;
          if (error.response && error.response.data) {
            if (error.response.data.token) {
              failedModalProps = {
                ...failedModalProps,
                contentText: error.response.data.token[0],
              };
            }
            if (error.response.data.non_field_errors) {
              failedModalProps = {
                ...failedModalProps,
                contentText: error.response.data.non_field_errors[0],
              };
            }
          }
          setGeneralModalProps(failedModalProps);
          setInputModalOpen(false);
          setGeneralModalOpen(true);
        });
    },
    rightButtonText: "CONFIRM",
  };

  const doYouWantToBookModalProps = {
    contentText: "Do you want want to book hairdresser's service?",
    headerText: null,
    itemData: null,
    leftButtonOnClick: () => setGeneralModalOpen(false),
    leftButtonText: "BACK",
    rightButtonOnClick: ({ offerId, dateTime }) => {
      api
        .post("/customer/service_order/", {
          offer: offerId,
          service_time: dateTime,
        })
        .then((res) => {
          let successModalProps = finalWordsBookedModalProps;
          if (res.data) {
            if (res.data.token) {
              successModalProps = {
                ...successModalProps,
                highlightedText: res.data.token,
              };
            }
            if (res.data.detail) {
              successModalProps = {
                ...successModalProps,
                contentText: res.data.detail,
              };
            }
          }
          setFinalWordsModalProps(successModalProps);
          setGeneralModalOpen(false);
          setFinalWordsModalOpen(true);
        })
        .catch((error) => {
          let failedModalProps = failedBookingModalProps;
          if (error.response && error.response.data) {
            if (error.response.data.offer) {
              failedModalProps = {
                ...failedModalProps,
                contentText: error.response.data.offer[0],
              };
            }
            if (error.response.data.service_time) {
              failedModalProps = {
                ...failedModalProps,
                contentText: error.response.data.service_time[0],
              };
            }
            if (error.response.data.non_field_errors) {
              failedModalProps = {
                ...failedModalProps,
                contentText: error.response.data.non_field_errors[0],
              };
            }
          }
          setFinalWordsModalProps(failedModalProps);
          setGeneralModalOpen(false);
          setFinalWordsModalOpen(true);
        });
    },
    rightButtonText: "BOOK",
  };

  const failedBookingModalProps = {
    buttonOnClick: () => setFinalWordsModalOpen(false),
    buttonText: "OK",
    contentText: "Booking hairdresser's service failed.",
    headerText: null,
    highlightedText: null,
  };

  const failedCancellationModalProps = {
    contentText: "Hairdresser's service cancellation failed.",
    headerText: null,
    leftButtonOnClick: () => setGeneralModalOpen(false),
    leftButtonText: "CLOSE",
    rightButtonOnClick: () => {
      setGeneralModalOpen(false);
      setInputModalOpen(true);
    },
    rightButtonText: "TRY AGAIN",
  };

  const finalWordsBookedModalProps = {
    buttonOnClick: () => setFinalWordsModalOpen(false),
    buttonText: "OK",
    contentText: "Successfully booked hairdresser's service.",
    headerText: null,
    highlightedText: "TOKEN",
  };

  const finalWordsCancelledModalProps = {
    buttonOnClick: () => setFinalWordsModalOpen(false),
    buttonText: "OK",
    contentText: "Successfully cancelled hairdresser's service.",
    headerText: null,
    highlightedText: null,
  };

  const redirectToLoginModalProps = {
    contentText:
      "Only signed in users can book and cancel hairdresser's services. Please sign in first.",
    headerText: null,
    leftButtonOnClick: () => setGeneralModalOpen(false),
    leftButtonText: "BACK",
    rightButtonOnClick: () => {
      localStorage.setItem("previousLocation", location.pathname);
      navigate("/customer/signin");
    },
    rightButtonText: "SIGN IN",
  };

  return (
    <Box
      sx={{
        px: 2,
        py: 4,
        mt: 5,
        mb: 1,
        borderRadius: 1,
        boxShadow: "0px 1px 5px 0px rgb(0 0 0 / 20%)",
      }}
    >
      <ModalBase
        open={finalWordsModalOpen || generalModalOpen || inputModalOpen}
        handleModalClose={() => {
          setFinalWordsModalOpen(false);
          setGeneralModalOpen(false);
          setInputModalOpen(false);
        }}
      >
        {finalWordsModalOpen ? (
          <TextOneButtonModalContent {...finalWordsModalProps} />
        ) : null}
        {generalModalOpen ? (
          <TextTwoButtonsModalContent {...generalModalProps} />
        ) : null}
        {inputModalOpen ? (
          <TextInputTwoButtonsModalContent {...inputModalProps} />
        ) : null}
      </ModalBase>
      <Grid container align="center" sx={{ mb: 3 }}>
        <Grid item xs={12}>
          <LocalizationProvider dateAdapter={AdapterDateFns}>
            <DesktopDatePicker
              label="service date"
              value={date}
              minDate={getMinDate({
                date: new Date(),
                openHours: offer.open_hours,
              })}
              onChange={(date) => {
                setDate(getMinDate({ date, openHours: offer.open_hours }));
              }}
              renderInput={(params) => <TextField {...params} />}
            />
          </LocalizationProvider>
        </Grid>
      </Grid>
      <Grid container columnSpacing={4} rowSpacing={2} justifyContent="center">
        {serviceTimesInfo.map((serviceInfo) => {
          return (
            <BookOrCancelBarberServiceItem
              bookServiceHandler={bookServiceHandler}
              cancelServiceHandler={cancelServiceHandler}
              key={serviceInfo.hourMinute}
              offerId={offer.id}
              serviceInfo={serviceInfo}
            />
          );
        })}
      </Grid>
    </Box>
  );
}
