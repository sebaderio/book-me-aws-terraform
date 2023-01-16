import Backdrop from "@mui/material/Backdrop";
import Box from "@mui/material/Box";
import Fade from "@mui/material/Fade";
import Modal from "@mui/material/Modal";
import { modalStyle } from "./modalStyle";

export default function ModalBase(props) {
  const { handleModalClose, open, children } = props;

  return (
    <Modal
      BackdropComponent={Backdrop}
      BackdropProps={{
        timeout: 500,
      }}
      aria-describedby="transition-modal-description"
      aria-labelledby="transition-modal-title"
      closeAfterTransition
      onClose={handleModalClose}
      open={open}
    >
      <Fade in={open}>
        <Box sx={modalStyle}>{children}</Box>
      </Fade>
    </Modal>
  );
}
