/**
 * 
 * @param {Function} fun 
 * @param {number} delay in ms
 */
function throttle(fun, delay) {
    let timeout = null

    return function () {
        let context = this

        let throttledCall = fun.apply(context, arguments)
        if (timeout !== null) {
            timeout = setTimeout(() => {
                throttledCall()
                clearTimeout(timeout)
            }, delay);
        }
    }
}

class ScrollListener extends HTMLElement {
    constructor() {
        super()

        this.handleIntersection = throttle(this.handleIntersection.bind(this), 300)
    }

    /**
     * 
     * @param {Array<IntersectionObserverEntry>} entries 
     */
    handleIntersection(entries) {
        let entry = entries[0]

        if (entry && entry.isIntersecting) {
            let event = new CustomEvent("intersected", {
                detail: entry.isIntersecting
            })

            this.dispatchEvent(event)
        }
    }

    connectedCallback() {
        this.node = document.createElement("div")

        this.node.setAttribute("data-test-id", "scroll-listener")

        this.node.style = "height: 1px; width: 1px; margin: -1px; pointer-events: none;"

        this.appendChild(this.node)

        this.observer = new IntersectionObserver(this.handleIntersection)

        this.observer.observe(this.node)
    }

    disconnectedCallback() {
        this.observer.unobserve(this.node)
    }
}

customElements.define("scroll-listener", ScrollListener)