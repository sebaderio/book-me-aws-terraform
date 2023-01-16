import { useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Container from "@mui/material/Container";
import { createTheme, ThemeProvider } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";
import BarberAvailability from "../components/BarberAvailability";
import BarberOfferDescription from "../components/BarberOfferDescription";
import Footer from "../components/Footer";
import Header from "../components/Header";
import useAxios from "../utils/useAxios";

const { REACT_APP_WS_BASE_URL } = process.env;
const WEBSOCKET_API_URL = `${REACT_APP_WS_BASE_URL}/websockets`;

const theme = createTheme();

export default function BarberOfferPage() {
  const { offer_id } = useParams();
  const [absences, setAbsences] = useState([]);
  const [offerDetails, setOfferDetails] = useState(null);
  const [orders, setOrders] = useState([]);
  const api = useAxios();
  const navigate = useNavigate();
  const absenceWs = useRef(null);
  const ordersWs = useRef(null);

  useEffect(() => {
    validateOfferIdParam();
    getServiceOfferDetails();
    connectToAbsenceWebsocket();
    connectToOrdersWebsocket();

    const absenceWsCurrent = absenceWs.current;
    const ordersWsCurrent = ordersWs.current;
    return () => {
      absenceWsCurrent.close();
      ordersWsCurrent.close();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const validateOfferIdParam = () => {
    if (!isOfferIdPositiveInt()) {
      navigate("/not_found");
    }
  };

  const isOfferIdPositiveInt = () =>
    !isNaN(offer_id) &&
    // eslint-disable-next-line eqeqeq
    parseInt(Number(offer_id)) == offer_id &&
    !isNaN(parseInt(offer_id, 10)) &&
    parseInt(offer_id, 10) > 0;

  const getServiceOfferDetails = () => {
    api
      .get(`/barber/service_offer/${offer_id}/`)
      .then((res) => {
        setOfferDetails(res.data);
      })
      .catch(() => {
        navigate("/not_found");
      });
  };

  const connectToAbsenceWebsocket = () => {
    absenceWs.current = new WebSocket(
      `${WEBSOCKET_API_URL}/service_unavailabilities/${offer_id}/`
    );
    absenceWs.current.onmessage = (e) => {
      const message = JSON.parse(e.data);
      setAbsences(message ? message : []);
    };
  };

  const connectToOrdersWebsocket = () => {
    ordersWs.current = new WebSocket(
      `${WEBSOCKET_API_URL}/service_orders/${offer_id}/`
    );
    ordersWs.current.onmessage = (e) => {
      const message = JSON.parse(e.data);
      setOrders(message ? message : []);
    };
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Container
        maxWidth="lg"
        sx={{
          bgcolor: "white",
          boxShadow: "0px 0px 20px 0px rgb(0 0 0 / 20%)",
          minHeight: "100vh",
        }}
      >
        <Header accountType={"CUSTOMER"} />
        <main>
          {offerDetails ? (
            <div>
              <BarberOfferDescription offerDetails={offerDetails} />
              <BarberAvailability
                absences={absences}
                orders={orders}
                offer={offerDetails}
              />
            </div>
          ) : null}
        </main>
        <Footer accountType={"CUSTOMER"} />
      </Container>
    </ThemeProvider>
  );
}
