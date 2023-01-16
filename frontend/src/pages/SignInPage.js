import { useContext, useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import Avatar from "@mui/material/Avatar";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import CssBaseline from "@mui/material/CssBaseline";
import Grid from "@mui/material/Grid";
import LockOutlinedIcon from "@mui/icons-material/LockOutlined";
import Paper from "@mui/material/Paper";
import TextField from "@mui/material/TextField";
import Typography from "@mui/material/Typography";
import { createTheme, ThemeProvider } from "@mui/material/styles";
import AuthContext from "../context/AuthContext";
import BlueUnderlinedTextTypography from "../components/BlueUnderlinedTextTypography";
import Footer from "../components/Footer";
import RedTextTypography from "../components/RedTextTypography";

const theme = createTheme();

const defaultFormErrors = {
  email: { error: false, errorMessage: "" },
  password: { error: false, errorMessage: "" },
  general: { error: false, errorMessage: "" },
};

export default function SignInPage() {
  let { loginUser, user } = useContext(AuthContext);
  const navigate = useNavigate();
  const [form, setForm] = useState(null);
  const [formErrors, setFormErrors] = useState(defaultFormErrors);

  const handleSubmit = (event) => {
    event.preventDefault();
    let errors = validateForm();
    if (errors !== defaultFormErrors) {
      setFormErrors(errors);
    } else {
      const data = new FormData(event.currentTarget);
      loginUser({
        email: data.get("email"),
        password: data.get("password"),
      }).then((response) => {
        if (response.status < 300) {
          const previousLocation = localStorage.getItem("previousLocation");
          navigate(previousLocation ? previousLocation : "/customer");
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
      if (response.email && response.email[0])
        errorMessages = {
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
            errorMessage: "No active account found with the given credentials.",
          },
        }
      : errorMessages;
  };

  const navigateToPreviousLocation = () => {
    const previousLocation = localStorage.getItem("previousLocation");
    return previousLocation ? (
      <Navigate to={previousLocation} />
    ) : (
      <Navigate to="/customer" />
    );
  };

  return user ? (
    navigateToPreviousLocation()
  ) : (
    <ThemeProvider theme={theme}>
      <Grid container component="main" sx={{ height: "100vh" }}>
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
              Sign In
            </Typography>
            <Box
              component="form"
              noValidate
              ref={(form) => setForm(form)}
              onSubmit={handleSubmit}
              sx={{ mt: 3, width: "100%" }}
            >
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    autoFocus
                    autoComplete="email"
                    error={formErrors.email.error}
                    helperText={formErrors.email.errorMessage}
                    fullWidth
                    required
                    id="email"
                    label="Email Address"
                    margin="normal"
                    name="email"
                    type="email"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    autoComplete="current-password"
                    error={formErrors.password.error}
                    helperText={formErrors.password.errorMessage}
                    fullWidth
                    required
                    id="password"
                    label="Password"
                    margin="normal"
                    name="password"
                    type="password"
                  />
                </Grid>
                <Grid item xs={12}>
                  <RedTextTypography variant="body2">
                    {formErrors.general.errorMessage}
                  </RedTextTypography>
                </Grid>
              </Grid>
              <Button
                fullWidth
                type="submit"
                variant="contained"
                sx={{ mt: 3, mb: 2 }}
              >
                Sign In
              </Button>
              <Grid container>
                <Grid item xs>
                  <BlueUnderlinedTextTypography
                    variant="body2"
                    onClick={() => navigate("/customer")}
                  >
                    Back to home
                  </BlueUnderlinedTextTypography>
                </Grid>
                <Grid item>
                  <BlueUnderlinedTextTypography
                    variant="body2"
                    onClick={() => {
                      navigate("/customer/signup");
                    }}
                  >
                    Don't have an account? Sign Up
                  </BlueUnderlinedTextTypography>
                </Grid>
              </Grid>
            </Box>
            <Footer accountType={"CUSTOMER"} />
          </Box>
        </Grid>
      </Grid>
    </ThemeProvider>
  );
}
