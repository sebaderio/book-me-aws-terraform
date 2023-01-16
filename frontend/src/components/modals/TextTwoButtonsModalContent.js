import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid";
import Typography from "@mui/material/Typography";

export default function TextTwoButtonsModalContent(props) {
  const {
    contentText,
    headerText,
    itemData,
    leftButtonOnClick,
    leftButtonText,
    rightButtonOnClick,
    rightButtonText,
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
      <Grid container sx={{ mt: 3, textAlign: "center" }}>
        <Grid item xs={6}>
          <Button onClick={leftButtonOnClick} size="medium" variant="contained">
            {leftButtonText}
          </Button>
        </Grid>
        <Grid item xs={6}>
          <Button
            onClick={() => {
              rightButtonOnClick(itemData);
            }}
            size="medium"
            variant="contained"
          >
            {rightButtonText}
          </Button>
        </Grid>
      </Grid>
    </div>
  );
}
