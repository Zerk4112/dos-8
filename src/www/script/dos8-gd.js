returned_data = null;
function addComment(name, comment) {
    console.log("Adding comment: ", name, comment);
    var timestamp = new Date().toLocaleString(); // Add a timestamp
    
    // Construct the Google Sheets URL with query parameters
    var sheetsURL = "https://docs.google.com/forms/d/e/1FAIpQLSf7V0IppAxTj4I464fqXmJAWlsLGVBV9h2Bi6q3oEZEECuqoQ/formResponse?";
    var formData = "entry.362293735=" + name +
                "&entry.1807660452=" + comment +
                "&entry.1238692157=" + timestamp;
    
    // Send data to Google Sheets using Fetch API
    fetch(sheetsURL + formData, {
        method: "POST",
        mode: "no-cors" // Enable CORS (Cross-Origin Resource Sharing)
    }).then(function(response) {
        // Handle response if needed
        console.log("Comment submitted successfully: ", response);
    }).catch(function(error) {
        console.error("Error submitting comment:", error);
    });
}

function fetchComments(force) {
    if (sessionStorage.getItem("comment_store")!=null && !force) {
        console.log("Using stored comments")
        returned_data = sessionStorage.getItem("comment_store");
        gpio[0]=4;
    } else {
        console.log("Fetching comments")
        fetch('http://localhost:3000/comments', {
        })
        .then(response => {
            console.log("Response:", response);
            return response.text();
        })
        .then(data => {
            // Process the data retrieved from the proxy server
            console.log("data: "+data);
            returned_data = data;
            // set all characters to lowercase
            returned_data = returned_data.toLowerCase();
            console.log("returned_data: "+returned_data);
            sessionStorage.setItem("comment_store", returned_data);
            gpio[0]=4;
        })
        .catch(error => {
            console.error('Error fetching comments:', error);
            gpio[4]=1;
            return error;
        });
    }
    
}