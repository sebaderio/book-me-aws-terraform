import { ThemeProvider } from "@emotion/react";
import { createTheme } from "@mui/material/styles";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid";
import Typography from "@mui/material/Typography";

const theme = createTheme({
  palette: {
    available: {
      main: "#1976d2",
      contrastText: "#fff",
    },
    busy: {
      main: "#d4d4d4",
      contrastText: "#fff",
    },
  },
});

export default function BookOrCancelBarberServiceItem(props) {
  const { bookServiceHandler, cancelServiceHandler, offerId, serviceInfo } =
    props;

  return (
    <ThemeProvider theme={theme}>
      <Grid item xs={11} sm={5} container>
        <Box
          sx={{
            p: 0.5,
            mb: 0.5,
            borderRadius: 8,
            boxShadow: "0px 0px 5px 0px rgb(0 0 0 / 20%)",
            width: "100%",
          }}
        >
          <Grid container spacing={3}>
            <Grid item xs={6}>
              <Box sx={{ m: 1, textAlign: "center" }}>
                <Typography
                  variant="h4"
                  sx={{
                    color: serviceInfo.isAvail
                      ? theme.palette.available.main
                      : theme.palette.busy.main,
                  }}
                >
                  {serviceInfo.hourMinute}
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={6} sx={{ textAlign: "center" }}>
              <Button
                color={serviceInfo.isAvail ? "available" : "busy"}
                component="div"
                onClick={() => {
                  if (serviceInfo.isAvail) {
                    bookServiceHandler({
                      offerId,
                      dateTime: serviceInfo.dateTime,
                    });
                  } else {
                    cancelServiceHandler({
                      offerId,
                      dateTime: serviceInfo.dateTime,
                    });
                  }
                }}
                size="medium"
                variant="contained"
                sx={{ m: 1.3, minWidth: 87 }}
              >
                {serviceInfo.isAvail ? "Book" : "Cancel"}
              </Button>
            </Grid>
          </Grid>
        </Box>
      </Grid>
    </ThemeProvider>
  );
}
