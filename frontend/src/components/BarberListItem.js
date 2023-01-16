import { useNavigate } from "react-router-dom";
import Avatar from "@mui/material/Avatar";
import Box from "@mui/material/Box";
import ButtonBase from "@mui/material/ButtonBase";
import Grid from "@mui/material/Grid";
import Skeleton from "@mui/material/Skeleton";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";

export default function BarberListItem(props) {
  const { id, address, barber_name, city, price, thumbnail } = props;
  const navigate = useNavigate();

  const handleClick = () => {
    navigate(`/hairdresser/service_offer/${id}`);
  };

  return (
    <Box
      onClick={handleClick}
      sx={{
        p: 2,
        mb: 3,
        borderRadius: 3,
        boxShadow: "0px 0px 5px 0px rgb(0 0 0 / 20%)",
      }}
    >
      <Grid container spacing={2}>
        <Grid item>
          <ButtonBase sx={{ width: 128, height: 128 }}>
            {thumbnail ? (
              <Avatar
                alt="Barber Image"
                src={thumbnail}
                sx={{ width: 128, height: 128 }}
                variant="rounded"
              />
            ) : (
              <Stack spacing={1} sx={{ width: 128, height: 128 }}>
                <Skeleton variant="text" animation={false} />
                <Skeleton
                  variant="circular"
                  width={20}
                  height={20}
                  animation={false}
                />
                <Skeleton
                  variant="rectangular"
                  width={128}
                  height={100}
                  animation={false}
                />
              </Stack>
            )}
          </ButtonBase>
        </Grid>
        <Grid item xs={12} sm container>
          <Grid item xs container direction="column" spacing={2}>
            <Grid item xs>
              <Typography gutterBottom variant="subtitle1" component="div">
                {barber_name}
              </Typography>
              <Typography variant="body2" gutterBottom>
                {city}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {address}
              </Typography>
            </Grid>
          </Grid>
          <Grid item>
            <Typography variant="subtitle1" component="div">
              {"$" + price}
            </Typography>
          </Grid>
        </Grid>
      </Grid>
    </Box>
  );
}
