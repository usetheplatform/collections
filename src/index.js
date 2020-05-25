import "./ScrollListener";
import { Elm } from "./Collections.elm";


const app = Elm.Collections.init({
    node: document.getElementById("app"),
    flags: process.env.ACCESS_KEY
});
