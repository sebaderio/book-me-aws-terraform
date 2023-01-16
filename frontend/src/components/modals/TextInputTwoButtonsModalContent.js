import { useState } from "react";
import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid";
import TextField from "@mui/material/TextField";
import Typography from "@mui/material/Typography";

export default function TextInputTwoButtonsModalContent(props) {
  const {
    contentText,
    headerText,
    inputValidators,
    leftButtonOnClick,
    leftButtonText,
    rightButtonOnClick,
    rightButtonText,
  } = props;
  const [input, setInput] = useState("");
  const [inputHelperText, setInputHelperText] = useState("");
  const [isInputError, setIsInputError] = useState(false);

  const handleRightButtonOnClick = () => {
    let inputErrorMessage = "";
    if (inputValidators && inputValidators.length > 0) {
      inputValidators.forEach((func) => {
        if (inputErrorMessage.length === 0) {
          inputErrorMessage = func(input);
        }
      });
    }
    if (inputErrorMessage.length === 0) {
      rightButtonOnClick(input);
    } else {
      setIsInputError(true);
      setInputHelperText(inputErrorMessage);
    }
  };

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
        <Grid item xs={12} sx={{ mb: 3.5 }}>
          <TextField
            label="token"
            error={isInputError}
            helperText={inputHelperText}
            variant="outlined"
            value={input}
            onChange={(e) => {
              setInput(e.target.value);
            }}
          />
        </Grid>
        <Grid item xs={6}>
          <Button onClick={leftButtonOnClick} size="medium" variant="contained">
            {leftButtonText}
          </Button>
        </Grid>
        <Grid item xs={6}>
          <Button
            onClick={handleRightButtonOnClick}
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
