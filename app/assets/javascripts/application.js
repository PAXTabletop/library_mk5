// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require_tree ../../../vendor/assets/javascripts
//= require_tree .

var bc_regex = /^[a-z]{3}[a-z0-9]{3,6}$/i;

const DEFAULT_ERROR = 'Something nasty occurred. Write down what you did for Mojo Jojo and try again.';

$(document).ready(function(){

    $.ajaxSetup({
        headers: {
            clientOffset: ((new Date()).getTimezoneOffset() / 60)
        }
    });

    setTimeout(pollStatus, 0);

    $('#suggest-btn').click(function(){
        $(this).hide();
        $('#suggest-form').show();
        $('#suggest-title').focus();
    });

    $('#cancel-suggest').click(function(){
        hideSuggest();
    });

    $('#save-suggest').click(function(){
        $.ajax({
            url: '/suggest',
            method: 'post',
            data: { title: $('#suggest-title').val() },
            success: function(response){
                if(response.title){
                    $.notify('Thanks for suggesting ' + response.title + '!');
                }
            },
            complete: function(){
                hideSuggest();
            }
        });
    });

});

function pollStatus(){
    $.get('/status').success(function(response){
        $('#total-games').text(response.total_games);
        $('#open-checkouts').text(response.open_checkouts);
        $('#longest-open-checkout').text(response.longest_open_checkout);

        setTimeout(pollStatus, 5000);
    });
}

function hideSuggest(){
    $('#suggest-form').hide();
    $('#suggest-btn').show();
    $('#suggest-title').val('');
}