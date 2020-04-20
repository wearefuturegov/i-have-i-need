import consumer from "../channels/consumer";

const contactId = parseInt(document.getElementById('contact_id').textContent);
let interval = null;
let updateNames = null;
let currentPeople = [];

const subscription = consumer.subscriptions.create({ channel: 'ContactChannel', id: contactId }, {
    connected() {
        this.perform("viewing", { "contact_id": contactId });
        interval = setInterval(() => { this.perform("viewing", { "contact_id": contactId }) }, 2000);
        updateNames = setInterval(() => {
            currentPeople = currentPeople.filter(p => p.lastSeen > Date.now() - 4000);
            const peopleList = document.getElementById("people-list");
            peopleList.textContent = '';
            currentPeople.forEach(p => {
                const li = document.createElement("li");
                li.appendChild(document.createTextNode(p.name));
                peopleList.appendChild(li);
            })

        }, 1000);
    },
    received(data) {
        const person = currentPeople.find(p => p.name === data);
        if (person == null) currentPeople.push({ name: data, lastSeen: Date.now() });
        else person.lastSeen = Date.now();
    },
    disconnected() {
        clearInterval(interval);
    }
});

const cleanup = () => {
    console.log("cleanup");
    clearInterval(interval);
    subscription.unsubscribe();
};

addEventListener("beforeunload", cleanup);
addEventListener("turbolinks:before-render", cleanup);