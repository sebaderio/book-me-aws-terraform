import Grid from "@mui/material/Grid";
import ImageWithCustomizableText from "./ImageWithCustomizableText";
import MarkdownList from "./MarkdownList";
import Sidebar from "./Sidebar";

export default function AppDescription(props) {
  const { mainImage, sideBar, reviews } = props;

  return (
    <div>
      <ImageWithCustomizableText data={mainImage} />
      <Grid container spacing={5} sx={{ mt: 3 }}>
        <MarkdownList title="Reviews" reviews={reviews} />
        <Sidebar {...sideBar} />
      </Grid>
    </div>
  );
}
