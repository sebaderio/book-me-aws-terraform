import { useEffect, useState } from "react";
import Box from "@mui/material/Box";
import TablePagination from "@mui/material/TablePagination";
import BarberListItem from "./BarberListItem";
import ImageWithCustomizableText from "./ImageWithCustomizableText";
import useAxios from "../utils/useAxios";

const notFoundImageData = {
  title: "Results not found...",
  description:
    "Please adjust searching criteria. Provide more precise hairdresser name, city where you would like to book a visit or hair salon address. ",
  image: "https://source.unsplash.com/random/?hairdresser",
  imageText: "Results not found.",
};

export default function BarberList(props) {
  const { searchPhrase } = props;
  const [numOfResults, setNumOfResults] = useState(0);
  const [page, setPage] = useState(0);
  const [results, setResults] = useState([]);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const api = useAxios();

  useEffect(() => {
    setPage(page);
    getFilteredBarbers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, searchPhrase, rowsPerPage]);

  const getFilteredBarbers = () => {
    api
      .get(
        `/barber/service_offers/?page_size=${rowsPerPage}&page=${
          page + 1
        }&search=${searchPhrase}`
      )
      .then((res) => {
        setNumOfResults(res.data.count);
        setResults(res.data.results);
      })
      .catch(() => {
        setNumOfResults(0);
        setResults([]);
      });
  };

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
  };

  return results && results.length > 0 ? (
    <Box sx={{ width: "100%" }}>
      {results.map((result, index) => {
        return <BarberListItem key={index} {...result} />;
      })}
      <TablePagination
        component="div"
        count={numOfResults}
        labelRowsPerPage={"Offers per page:"}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
        page={page}
        rowsPerPage={rowsPerPage}
        rowsPerPageOptions={[5, 10, 25, 50]}
      />
    </Box>
  ) : (
    <ImageWithCustomizableText data={notFoundImageData} />
  );
}
