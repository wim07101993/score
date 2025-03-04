
// async function callAuth() {
//     // const redirectUri = encodeURIComponent('http://localhost:63344/frontend/src/index.html');
//     // const uri = `http://localhost:7003/oauth/v2/authorize?client_id=${clientId}&redirect_uri=${redirectUri}&scope=${scope}`
//     const uri = new URL('http://localhost:7003/oauth/v2/authorize');
//     uri.searchParams.append('client_id', '308439685552734211')
//     uri.searchParams.append('redirect_uri', 'http://localhost:63344/frontend/src/index.html');
//     uri.searchParams.append('scope', 'openid');
//     uri.searchParams.append('response_type', 'code')
//     console.log(uri.toString());
//     const response = await fetch(uri)
//     console.log(response.text());
// }
//
// callAuth();

if (!window.Worker) {
    throw "Your browser does not support web workers which are required for the application to work."
}

const myWorker = new Worker("score_fetcher.js", {type: "module"});

// the message does not matter, score_fetcher.js does not check it.
myWorker.postMessage("")
