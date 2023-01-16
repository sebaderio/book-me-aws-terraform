import PropTypes from "prop-types";
import Box from "@mui/material/Box";
import Divider from "@mui/material/Divider";
import Grid from "@mui/material/Grid";
import Typography from "@mui/material/Typography";
import MarkdownItem from "./MarkdownItem";

function MarkdownList(props) {
  const { reviews, title } = props;

  return (
    <Grid
      item
      xs={12}
      md={8}
      sx={{
        "& .markdown": {
          py: 3,
        },
      }}
    >
      <Typography variant="h6" gutterBottom>
        {title}
      </Typography>
      <Divider />
      {reviews.map((review, index) => (
        <Box key={index}>
          <MarkdownItem className="markdown">{review}</MarkdownItem>
          <Divider variant="middle" />
        </Box>
      ))}
    </Grid>
  );
}

MarkdownList.propTypes = {
  reviews: PropTypes.arrayOf(PropTypes.string).isRequired,
  title: PropTypes.string.isRequired,
};

export default MarkdownList;
