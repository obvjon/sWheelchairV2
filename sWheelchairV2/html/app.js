const { createApp } = Vue;

function postNUI(event, data = {}) {
    return fetch(`https://sWheelchairV2/${event}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(data),
    });
}

const app = createApp({
    data() {
        return {
            visible: false,
            labels: {
                Title: "Wheelchair",
                Subtitle: "Temporary mobility restriction",
                IdLabel: "Player ID",
                IdHint: "Enter in-game server ID.",
                TimeLabel: "Time (minutes)",
                TimeHint: "How long to keep them in the wheelchair.",
                Apply: "Apply Sentence",
                Close: "Close",
            },
            form: {
                targetId: "",
                minutes: "",
            },

            // drag
            isDragging: false,
            dragOffsetX: 0,
            dragOffsetY: 0,
            windowEl: null,
            headerEl: null,
        };
    },

    methods: {
        //------------------------------------------------------
        // DRAG
        //------------------------------------------------------
        initDrag() {
            this.windowEl = this.$refs.window;
            this.headerEl = this.$refs.header;

            const win = this.windowEl;
            const header = this.headerEl;
            if (!win || !header) return;

            this.teardownDrag();

            this._dragMove = (e) => {
                if (!this.isDragging) return;
                win.style.left = `${e.clientX - this.dragOffsetX}px`;
                win.style.top = `${e.clientY - this.dragOffsetY}px`;
                win.style.transform = "none";
            };

            this._dragUp = () => {
                this.isDragging = false;
            };

            this._dragDown = (e) => {
                this.isDragging = true;
                this.dragOffsetX = e.clientX - win.offsetLeft;
                this.dragOffsetY = e.clientY - win.offsetTop;
            };

            header.addEventListener("mousedown", this._dragDown);
            document.addEventListener("mousemove", this._dragMove);
            document.addEventListener("mouseup", this._dragUp);
        },

        teardownDrag() {
            const header = this.headerEl;

            if (header && this._dragDown)
                header.removeEventListener("mousedown", this._dragDown);
            if (this._dragMove)
                document.removeEventListener("mousemove", this._dragMove);
            if (this._dragUp)
                document.removeEventListener("mouseup", this._dragUp);

            this.isDragging = false;
            this._dragMove = null;
            this._dragUp = null;
            this._dragDown = null;
        },

        //------------------------------------------------------
        // UI
        //------------------------------------------------------
        close() {
            this.visible = false;
            postNUI("close", {});
        },

        submit() {
            const data = {
                targetId: this.form.targetId,
                minutes: this.form.minutes,
            };

            if (!data.targetId || !data.minutes || data.minutes <= 0) return;

            postNUI("submitSentence", data);
        },

        handleOpen(payload) {
            this.visible = true;

            if (payload.labels) {
                this.labels = Object.assign({}, this.labels, payload.labels);
            }

            if (payload.theme) {
                for (const k in payload.theme) {
                    document.documentElement.style.setProperty(
                        `--${k.replace(/_/g, "-")}`,
                        payload.theme[k]
                    );
                }
            }

            this.$nextTick(() => {
                this.teardownDrag();
                this.initDrag();
            });
        },
    },

    mounted() {
        this._messageHandler = (event) => {
            const d = event.data;
            if (!d || !d.action) return;

            if (d.action === "open") {
                this.handleOpen(d.payload || {});
            } else if (d.action === "close") {
                this.visible = false;
            }
        };

        window.addEventListener("message", this._messageHandler);

        window.addEventListener("keydown", (e) => {
            if (e.key === "Escape") {
                postNUI("escape", {});
            }
        });
    },

    unmounted() {
        this.teardownDrag();
        if (this._messageHandler) {
            window.removeEventListener("message", this._messageHandler);
        }
    },
});

app.mount("#app");
