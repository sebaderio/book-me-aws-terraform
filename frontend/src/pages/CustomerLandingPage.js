import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import Container from "@mui/material/Container";
import CssBaseline from "@mui/material/CssBaseline";
import FacebookIcon from "@mui/icons-material/Facebook";
import RedditIcon from "@mui/icons-material/Reddit";
import TwitterIcon from "@mui/icons-material/Twitter";
import { createTheme, ThemeProvider } from "@mui/material/styles";
import AppDescription from "../components/AppDescription";
import BarberList from "../components/BarberList";
import Footer from "../components/Footer";
import Header from "../components/Header";
import SearchBar from "../components/SearchBar";
import customerReviews from "../components/CustomerReviews";

const mainImageWithTextProps = {
  title: "Getting a new haircut easier than ever before...",
  description:
    "BookMe is a free booking platform, in which you can easily find a free date and make an appointment conveniently. No calling - you book anytime and from everywhere.",
  image: "https://source.unsplash.com/random/?hairdresser",
  imageText: "Image not available.",
};

const sidebarProps = {
  title: "About",
  description:
    "BookMe is a group of geeks that strives to take the hairdressing industry to the next level. We do our best to allow people around the world to book hairdresser's service seamlessly.",
  social: [
    { name: "Twitter", icon: TwitterIcon, url: "https://twitter.com/bookme" },
    {
      name: "Facebook",
      icon: FacebookIcon,
      url: "https://facebook.com/bookme",
    },
    { name: "Reddit", icon: RedditIcon, url: "https://reddit.com/bookme" },
  ],
};

const searchBarStyle = {
  margin: "0 auto",
  marginTop: 80,
  marginBottom: 80,
  maxWidth: 800,
  height: 60,
  boxShadow: "0px 0px 5px 0px rgb(0 0 0 / 20%)",
};

const theme = createTheme();

export default function CustomerLandingPage() {
  const [searchParams] = useSearchParams();
  const [searchPhrase, setSearchPhrase] = useState(null);
  const [pendingSearchPhrase, setPendingSearchPhrase] = useState("");
  const navigate = useNavigate();

  useEffect(() => {
    setSearchPhrase(searchParams.get("search"));
    setPendingSearchPhrase(
      searchParams.get("search") ? searchParams.get("search") : ""
    );
  }, [searchParams]);

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
          <SearchBar
            value={pendingSearchPhrase}
            onChange={(searchText) => setPendingSearchPhrase(searchText)}
            onRequestSearch={() => {
              if (pendingSearchPhrase) {
                navigate(`/customer?search=${pendingSearchPhrase}`);
              } else {
                navigate("/customer");
              }
            }}
            style={searchBarStyle}
          />
          {searchPhrase && searchPhrase.length > 0 ? (
            <BarberList searchPhrase={searchPhrase} />
          ) : (
            <AppDescription
              mainImage={mainImageWithTextProps}
              sideBar={sidebarProps}
              reviews={customerReviews}
            />
          )}
        </main>
        <Footer accountType={"CUSTOMER"} />
      </Container>
    </ThemeProvider>
  );
}
