import Avatar from "@mui/material/Avatar";
import Box from "@mui/material/Box";
import ButtonBase from "@mui/material/ButtonBase";
import Divider from "@mui/material/Divider";
import Grid from "@mui/material/Grid";
import Skeleton from "@mui/material/Skeleton";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";

const OfferDescriptionDivider = ({ text }) => {
  return (
    <Divider sx={{ m: 2 }} textAlign="center">
      {text}
    </Divider>
  );
};

const OfferDetailsItem = ({ name, value }) => {
  return (
    <Box sx={{ textAlign: "center", color: "#1976d2" }}>
      <Typography>{name}</Typography>
      <Typography>{value}</Typography>
    </Box>
  );
};

export default function BarberOfferDescription(props) {
  const { offerDetails } = props;
  return (
    <Box
      sx={{
        p: 2,
        mt: 5,
        mb: 2,
        borderRadius: 1,
        boxShadow: "0px 1px 5px 0px rgb(0 0 0 / 20%)",
      }}
    >
      <Grid container spacing={3}>
        <Grid item>
          <ButtonBase sx={{ width: 128, height: 128 }}>
            {offerDetails.thumbnail ? (
              <Avatar
                alt="Barber Image"
                src={offerDetails.thumbnail}
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
          <Grid item xs container direction="column">
            <Grid item xs>
              <Typography gutterBottom variant="h4" component="div">
                {offerDetails.barber_name}
              </Typography>
              <OfferDescriptionDivider text={"Address"} />
              <Typography align="center" variant="body1" gutterBottom>
                {offerDetails.city}
              </Typography>
              <Typography align="center" variant="body2">
                {offerDetails.address}
              </Typography>
              <OfferDescriptionDivider text={"Description"} />
              <Typography align="center" variant="body2">
                {offerDetails.description}
              </Typography>
              <OfferDescriptionDivider text={"Details"} />
              <Grid item container justifyContent="center">
                <Box>
                  <Stack
                    direction={{ xs: "column", sm: "row" }}
                    divider={<Divider orientation="vertical" flexItem />}
                    spacing={{ xs: 1, sm: 2, md: 4 }}
                  >
                    <OfferDetailsItem
                      name={"Specialization"}
                      value={offerDetails.specialization}
                    />
                    <OfferDetailsItem
                      name={"Open Hours"}
                      value={offerDetails.open_hours}
                    />
                    <OfferDetailsItem
                      name={"Working Days"}
                      value={offerDetails.working_days}
                    />
                  </Stack>
                </Box>
              </Grid>
            </Grid>
          </Grid>
          <Grid item>
            <Typography variant="h6" component="div">
              {"$" + offerDetails.price}
            </Typography>
          </Grid>
        </Grid>
      </Grid>
    </Box>
  );
}
