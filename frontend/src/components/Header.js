import { Fragment, useContext } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Avatar from "@mui/material/Avatar";
import Button from "@mui/material/Button";
import Stack from "@mui/material/Stack";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import AuthContext from "../context/AuthContext";

const { REACT_APP_API_BASE_URL } = process.env;

function Header(props) {
  const { accountType } = props;
  let { logoutUser, user } = useContext(AuthContext);
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <Fragment>
      <Toolbar
        sx={{ borderBottom: 1.2, borderColor: "divider", marginBottom: 2 }}
      >
        <Avatar
          alt="BookMe Logo"
          src="/media/bookme_200.png"
          onClick={() =>
            // NOTE: For customers navigate to "/" instead of "/customer", because it clears
            // search results and redirects to the rerendered "/customer" displaying app description.
            navigate(accountType === "CUSTOMER" ? "/" : "/hairdresser")
          }
        />
        <Typography
          component="h2"
          variant="h5"
          color="inherit"
          align="center"
          noWrap
          sx={{ flex: 1, color: "#1976d2" }}
        ></Typography>
        {!user ? (
          <Stack direction="row" spacing={1}>
            <Button
              variant="contained"
              size="medium"
              onClick={() => {
                if (accountType === "BARBER") {
                  navigate(location.pathname);
                  window.location.replace(
                    `${REACT_APP_API_BASE_URL}/admin/`,
                    "_blank"
                  );
                } else {
                  localStorage.setItem("previousLocation", location.pathname);
                  navigate("/customer/signin");
                }
              }}
            >
              SIGN IN
            </Button>
            <Button
              variant="contained"
              size="medium"
              onClick={() => {
                localStorage.setItem("previousLocation", location.pathname);
                navigate(
                  accountType === "CUSTOMER"
                    ? "/customer/signup"
                    : "/hairdresser/signup"
                );
              }}
            >
              SIGN UP
            </Button>
          </Stack>
        ) : (
          <Stack direction="row" spacing={1}>
            <Button variant="contained" size="medium" onClick={logoutUser}>
              LOGOUT
            </Button>
          </Stack>
        )}
      </Toolbar>
    </Fragment>
  );
}

export default Header;
