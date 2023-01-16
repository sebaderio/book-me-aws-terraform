import { useNavigate } from "react-router-dom";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Typography from "@mui/material/Typography";

function Copyright(props) {
  const { accountType } = props;
  const navigate = useNavigate();

  return (
    <Typography
      variant="body2"
      color="text.secondary"
      align="center"
      onClick={() =>
        accountType === "BARBER"
          ? navigate("/hairdresser")
          : navigate("/customer")
      }
    >
      Copyright © BookMe Inc. {new Date().getFullYear()}
      {"."}
    </Typography>
  );
}

function Footer(props) {
  const { accountType } = props;

  return (
    <Box component="footer" sx={{ bgcolor: "white", py: 4 }}>
      <Container maxWidth="lg">
        <Copyright accountType={accountType} />
      </Container>
    </Box>
  );
}

export default Footer;
