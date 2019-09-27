// Enable skip button before the 5th day of each month
(function allowSkipBeforeFifth() {
  var today = new Date();
  var localTime = today.getTime();
  var timezoneoffset = today.getTimezoneOffset() * 60000;
  var utcTime = localTime + timezoneoffset;
  var ptOffset = -7;
  var ptTime = utcTime + (3600000 * ptOffset);
  var todayPacificTime = new Date(ptTime);

  function convertToPT(today) {
    var localTime = today.getTime();
    var timezoneoffset = today.getTimezoneOffset() * 60000;
    var utcTime = localTime + timezoneoffset;
    var ptOffset = -7;
    var ptTime = utcTime + (3600000 * ptOffset);

    return new Date(ptTime);
  }

  // ---- Timer code ----
var todayYear = parseInt(todayPacificTime.getFullYear());
var todayLocalMonth = parseInt(todayPacificTime.getMonth());
var todayLocalDay = parseInt(todayPacificTime.getDate());
var todayLocalHour = parseInt(todayPacificTime.getHours());
var lastDayMonth = lastday(todayYear, todayLocalMonth);
var lastDayThisMonth = parseInt(lastDayMonth.getDate());

function lastday(y,m){
  return  new Date(y, m+1, 0);
}

var endTime = lastday(todayYear, todayLocalMonth);
// console.log('endTime', endTime)

var endTimePT = convertToPT(endTime);
// console.log('endTimePT', endTimePT)

var endTimeMidnight = new Date(endTime.setDate(endTime.getDate() + 1));
// console.log('endTimeMidngight', new Date(endTimeMidnight))

function makeTimer(endTime) {

  //		var endTime = new Date("29 April 2018 9:56:00 GMT+01:00");
  endTime = (Date.parse(endTime) / 1000);

  var now = new Date();
  now = (Date.parse(now) / 1000);

  var timeLeft = endTime - now;
  // console.log('timeleft', timeLeft)

  if (timeLeft <= 0) {
    $('.rolloverMidnightWarning').hide();
  }

  var days = Math.floor(timeLeft / 86400);
  var hours = Math.floor((timeLeft - (days * 86400)) / 3600);
  var minutes = Math.floor((timeLeft - (days * 86400) - (hours * 3600 )) / 60);
  var seconds = Math.floor((timeLeft - (days * 86400) - (hours * 3600) - (minutes * 60)));

  if (hours < "10") { hours = "0" + hours; }
  if (minutes < "10") { minutes = "0" + minutes; }
  if (seconds < "10") { seconds = "0" + seconds; }

  // $("#days").html(days + "<span>Days</span>");
  $("#hours").html(hours + "<span>Hours</span>");
  $("#minutes").html(minutes + "<span>Minutes</span>");
  $("#seconds").html(seconds + "<span>Seconds</span>");

}

// console.log('today', todayLocalDay)
// console.log('lastday', lastDayThisMonth)
// console.log('localhour', todayLocalHour)

if (todayLocalDay == lastDayThisMonth && todayLocalHour > 20) {
  setInterval(function() { makeTimer(endTimeMidnight); }, 1000);
    // Show messaging:
    $('.rolloverMidnightWarning').show();
    // console.log('show!')
  }

  if (todayLocalDay < 5) {
    // $('.tabsWrapper .tab-2').show();
    // $('.showOnMobile798 .tab-2').show();
  } else {
    // TODO: grey skip button

    if ($('#july_allow_skip').val()) {

    } else {
      $('.tabsWrapper .tab-2').css('cursor', 'default').css('color', 'gray');
      // $('.tabsWrapper .tab-2').attr('data-disabled', true);

      $('.showOnMobile798 .tab-2').css('cursor', 'default').css('color', 'gray');
      // $('.showOnMobile798 .tab-2').attr('data-disabled', true);
    }

  }
})();
