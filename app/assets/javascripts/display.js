$(document).ready(function(){
    $.ajaxSetup({
        headers: {
            clientOffset: ((new Date()).getTimezoneOffset() / 60)
        }
    });

    setTimeout(updateDisplay, 0);
});

function updateDisplay(){
    $.get('/display/status').success(function(response){
        //console.log("success");
        console.log(response);
        $('#total-checkouts').text(response.total_checkouts);
        $('#total-games').text(response.total_games);
        $('#open-checkouts').text(response.open_checkouts);
        if (response.longest_checkout !== null) {
            $('#longest-checkout').text(response.longest_checkout.min_game);
        }
        if (response.top_games !== null) {
            $('#top-games').html(response.top_games);
        }
        setTimeout(updateDisplay, 5000);
    });
}