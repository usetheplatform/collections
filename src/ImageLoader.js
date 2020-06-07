class ImageLoader extends HTMLElement {

    constructor() {
        super()

        this.status = "loading";
        this.handleLoad = this.handleLoad.bind(this)
        this.handleError = this.handleError.bind(this)
    }

    handleLoad(event) {
        this.status = "loaded"

        this.render()
    }

    // TODO: Handle error
    handleError() {
        this.status = "errored"

        this.render()
    }

    connectedCallback() {
        this.image = document.createElement("img")

        this.image.classList.add("gallery__image")
        this.image.setAttribute("data-image-id", this.id)
        this.image.setAttribute("loading", this.loading ? this.loading : "eager")
        this.image.setAttribute("alt", this.alt)

        this.render()

        this.image.onload = this.handleLoad
        this.image.onerror = this.handleError
        this.image.src = this.src
    }

    render() {
        switch (this.status) {
            case "loading":
                this.appendChild(this.image)

                break;
            case "errored":
                break;

            case "loaded":
                this.image.classList.add("gallery__image--loaded")
                break;
            default:
                break;
        }
    }
}

customElements.define("image-loader", ImageLoader)