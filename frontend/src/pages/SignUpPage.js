import { useContext, useState } from "react";
import { useLocation, Navigate, useNavigate } from "react-router-dom";
import { createTheme, ThemeProvider } from "@mui/material/styles";
import Avatar from "@mui/material/Avatar";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Checkbox from "@mui/material/Checkbox";
import CssBaseline from "@mui/material/CssBaseline";
import FormControlLabel from "@mui/material/FormControlLabel";
import Grid from "@mui/material/Grid";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import Paper from "@mui/material/Paper";
import TextField from "@mui/material/TextField";
import Typography from "@mui/material/Typography";
import AuthContext from "../context/AuthContext";
import BlueUnderlinedTextTypography from "../components/BlueUnderlinedTextTypography";
import Footer from "../components/Footer";
import RedTextTypography from "../components/RedTextTypography";
import ModalBase from "../components/modals/ModalBase";
import TextOneButtonModalContent from "../components/modals/TextOneButtonModalContent";

const { REACT_APP_API_BASE_URL } = process.env;
const theme = createTheme();

const defaultFormErrors = {
  firstName: { error: false, errorMessage: "" },
  lastName: { error: false, errorMessage: "" },
  email: { error: false, errorMessage: "" },
  password: { error: false, errorMessage: "" },
  general: { error: false, errorMessage: "" },
};

export default function SignUpPage(props) {
  const { accountType } = props;
  let { registerUser, user } = useContext(AuthContext);
  const location = useLocation();
  const navigate = useNavigate();
  const [acceptedNewsletter, setAcceptedNewsletter] = useState(false);
  const [form, setForm] = useState(null);
  const [formErrors, setFormErrors] = useState(defaultFormErrors);
  const [modalText, setModalText] = useState(
    "Thank You for registering. An email with account activation link was sent to You."
  );
  const [open, setModalOpen] = useState(false);

  const handleModalClose = () => {
    setModalOpen(false);
    navigate(accountType === "CUSTOMER" ? "/customer" : "/hairdresser");
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    let errors = validateForm();
    if (errors !== defaultFormErrors) {
      setFormErrors(errors);
    } else {
      const data = new FormData(event.currentTarget);
      registerUser({
        name: data.get("firstName"),
        surname: data.get("lastName"),
        email: data.get("email"),
        password: data.get("password"),
        accepted_newsletter: acceptedNewsletter,
        account_type: accountType,
      }).then((response) => {
        if (response.status < 300) {
          if (response.data && response.data.detail) {
            setModalText(response.data.detail);
          }
          setModalOpen(true);
        } else {
          setFormErrors({
            ...defaultFormErrors,
            ...getResponseErrors(response.data),
          });
        }
      });
    }
  };

  const validateForm = () => {
    if (!form) {
      return {
        general: { error: true, errorMessage: "Please fill out this form." },
      };
    }

    const formLength = form.length;
    const errors = { general: { error: false, errorMessage: "" } };
    if (form.checkValidity() === false) {
      for (let i = 0; i < formLength; i++) {
        const elem = form[i];
        if (Object.keys(formErrors).includes(elem.name)) {
          if (!elem.validity.valid) {
            errors[elem.name] = {
              error: true,
              errorMessage: elem.validationMessage,
            };
          } else {
            errors[elem.name] = {
              error: false,
              errorMessage: "",
            };
          }
        }
      }
      return { ...formErrors, ...errors };
    } else {
      return defaultFormErrors;
    }
  };

  const getResponseErrors = (response) => {
    let errorMessages = {};
    if (response) {
      if (response.name && response.name[0])
        errorMessages = {
          firstName: { error: true, errorMessage: response.name[0] },
        };
      if (response.surname && response.surname[0])
        errorMessages = {
          ...errorMessages,
          lastName: { error: true, errorMessage: response.surname[0] },
        };
      if (response.email && response.email[0])
        errorMessages = {
          ...errorMessages,
          email: { error: true, errorMessage: response.email[0] },
        };
      if (response.password && response.password[0])
        errorMessages = {
          ...errorMessages,
          password: { error: true, errorMessage: response.password[0] },
        };
      if (response.detail)
        errorMessages = {
          ...errorMessages,
          general: { error: true, errorMessage: response.detail },
        };
    }
    return errorMessages === {}
      ? {
          general: {
            error: true,
            errorMessage:
              "Cannot create an account with the given credentials.",
          },
        }
      : errorMessages;
  };

  const redirectToPreviousLocation = () => {
    const previousLocation = localStorage.getItem("previousLocation");
    return previousLocation ? (
      <Navigate to={previousLocation} />
    ) : (
      <Navigate
        to={accountType === "CUSTOMER" ? "/customer" : "/hairdresser"}
      />
    );
  };

  return user ? (
    redirectToPreviousLocation()
  ) : (
    <ThemeProvider theme={theme}>
      <Grid container component="main" sx={{ height: "100vh" }}>
        <ModalBase open={open} handleModalClose={handleModalClose}>
          <TextOneButtonModalContent
            buttonOnClick={handleModalClose}
            buttonText={"OK"}
            contentText={modalText}
            headerText={"Success!"}
          />
        </ModalBase>
        <CssBaseline />
        <Grid
          item
          xs={false}
          sm={4}
          md={7}
          sx={{
            backgroundImage:
              "url(https://source.unsplash.com/random/?hairdresser)",
            backgroundRepeat: "no-repeat",
            backgroundColor: (t) =>
              t.palette.mode === "light"
                ? t.palette.grey[50]
                : t.palette.grey[900],
            backgroundSize: "cover",
            backgroundPosition: "center",
          }}
        />
        <Grid item xs={12} sm={8} md={5} component={Paper} elevation={6} square>
          <Box
            sx={{
              my: 8,
              mx: 4,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
            }}
          >
            <Avatar sx={{ m: 1, bgcolor: "#1976d2" }}>
              <LockOutlinedIcon />
            </Avatar>
            <Typography component="h1" variant="h5">
              Sign Up
            </Typography>
            <Box
              component="form"
              noValidate
              ref={(form) => setForm(form)}
              onSubmit={handleSubmit}
              sx={{ mt: 3 }}
            >
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    autoFocus
                    autoComplete="given-name"
                    error={formErrors.firstName.error}
                    helperText={formErrors.firstName.errorMessage}
                    fullWidth
                    required
                    id="firstName"
                    label="First Name"
                    name="firstName"
                    type="text"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    autoComplete="family-name"
                    error={formErrors.lastName.error}
                    helperText={formErrors.lastName.errorMessage}
                    fullWidth
                    required
                    id="lastName"
                    label="Last Name"
                    name="lastName"
                    type="text"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    autoComplete="email"
                    error={formErrors.email.error}
                    helperText={formErrors.email.errorMessage}
                    required
                    fullWidth
                    id="email"
                    label="Email Address"
                    name="email"
                    type="email"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    autoComplete="new-password"
                    error={formErrors.password.error}
                    helperText={formErrors.password.errorMessage}
                    required
                    fullWidth
                    id="password"
                    label="Password"
                    name="password"
                    type="password"
                  />
                </Grid>
                <Grid item xs={12}>
                  <RedTextTypography variant="body2">
                    {formErrors.general.errorMessage}
                  </RedTextTypography>
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        id="acceptedNewsletter"
                        name="acceptedNewsletter"
                        color="primary"
                      />
                    }
                    checked={acceptedNewsletter}
                    onChange={() => setAcceptedNewsletter(!acceptedNewsletter)}
                    label="I want to receive inspiration, marketing promotions and updates via email."
                  />
                </Grid>
              </Grid>
              <Button
                type="submit"
                fullWidth
                variant="contained"
                sx={{ mt: 3, mb: 2 }}
              >
                Sign Up
              </Button>
              <Grid container>
                <Grid item xs>
                  <BlueUnderlinedTextTypography
                    variant="body2"
                    onClick={() => {
                      navigate(
                        accountType === "CUSTOMER"
                          ? "/customer"
                          : "/hairdresser"
                      );
                    }}
                  >
                    Back to home
                  </BlueUnderlinedTextTypography>
                </Grid>
                <Grid item>
                  <BlueUnderlinedTextTypography
                    variant="body2"
                    onClick={() => {
                      if (accountType === "BARBER") {
                        navigate(location.pathname);
                        window.location.replace(
                          `${REACT_APP_API_BASE_URL}/admin/`,
                          "_blank"
                        );
                      } else {
                        navigate("/customer/signin");
                      }
                    }}
                  >
                    Already have an account? Sign in
                  </BlueUnderlinedTextTypography>
                </Grid>
              </Grid>
            </Box>
            <Footer accountType={accountType} />
          </Box>
        </Grid>
      </Grid>
    </ThemeProvider>
  );
}
