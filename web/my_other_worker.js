self.onmessage = function (event) {
  const data = event.data;
  console.log("Worker (JS) received:", data);

  if (typeof data === "number") {
    console.log("Worker (JS) starting calculation...");

    setTimeout(() => {
      const result = data * 2;
      console.log("Worker (JS) finished calculation, sending:", result);
      self.postMessage(result);
    }, 3000);
  } else {
    console.log("Worker (JS) received invalid data type.");
    self.postMessage("Invalid data type received");
  }
};

console.log("Worker (JS) initialized");

self.postMessage("Worker Ready");
