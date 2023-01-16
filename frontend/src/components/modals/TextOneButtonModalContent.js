import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Typography from "@mui/material/Typography";

export default function TextOneButtonModalContent(props) {
  const {
    buttonOnClick,
    buttonText,
    contentText,
    headerText,
    highlightedText,
  } = props;

  return (
    <div>
      <Typography
        align="center"
        component="h2"
        id="transition-modal-title"
        variant="h6"
      >
        {headerText}
      </Typography>
      <Typography
        align="center"
        id="transition-modal-description"
        sx={{ mt: 2 }}
      >
        {contentText}
      </Typography>
      <Typography align="center" sx={{ mt: 3, color: "#1976d2" }} variant="h4">
        {highlightedText}
      </Typography>
      <Box sx={{ mt: 3 }} textAlign="center">
        <Button onClick={buttonOnClick} size="medium" variant="contained">
          {buttonText}
        </Button>
      </Box>
    </div>
  );
}
