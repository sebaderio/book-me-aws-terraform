import { createContext, useState, useEffect } from "react";
import axios from "axios";
import jwt_decode from "jwt-decode";

const { REACT_APP_API_BASE_URL } = process.env;
const AuthContext = createContext();

export default AuthContext;

export const AuthProvider = ({ children }) => {
  let [authTokens, setAuthTokens] = useState(() =>
    localStorage.getItem("authTokens")
      ? JSON.parse(localStorage.getItem("authTokens"))
      : null
  );
  let [user, setUser] = useState(() =>
    localStorage.getItem("authTokens")
      ? jwt_decode(localStorage.getItem("authTokens"))
      : null
  );
  let [loading, setLoading] = useState(true);

  let loginUser = async (data) => {
    let result = null;
    await axios
      .post(`${REACT_APP_API_BASE_URL}/auth/login/customer/`, data)
      .then((response) => {
        setAuthTokens(response.data);
        setUser(jwt_decode(response.data.access));
        localStorage.setItem("authTokens", JSON.stringify(response.data));
        result = response;
      })
      .catch((error) => {
        if (error.response) {
          result = error.response;
        } else {
          alert("Something went wrong!");
        }
      });

    return result;
  };

  let logoutUser = () => {
    setAuthTokens(null);
    setUser(null);
    localStorage.removeItem("authTokens");
  };

  let registerUser = async (data) => {
    let result = null;
    await axios
      .post(`${REACT_APP_API_BASE_URL}/auth/register/`, data)
      .then((response) => {
        result = response;
      })
      .catch((error) => {
        if (error.response) {
          result = error.response;
        } else {
          alert("Something went wrong!");
        }
      });

    return result;
  };

  let contextData = {
    user: user,
    authTokens: authTokens,
    setAuthTokens: setAuthTokens,
    setUser: setUser,
    loginUser: loginUser,
    logoutUser: logoutUser,
    registerUser: registerUser,
  };

  useEffect(() => {
    if (authTokens) {
      setUser(jwt_decode(authTokens.access));
    }
    setLoading(false);
  }, [authTokens, loading]);

  return (
    <AuthContext.Provider value={contextData}>
      {loading ? null : children}
    </AuthContext.Provider>
  );
};
