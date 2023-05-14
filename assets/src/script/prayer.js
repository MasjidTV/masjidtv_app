// Get today date
const today = new Date();
let todayDay = today.getDate();
console.log(todayDay);


// read JSON file
fetch('../../config.json')
    .then(response => response.json())
    .then(setting => {
        fetch('../../db/May-2023.processed.json')
            .then(response => response.json())
            .then(parsed_data => {
                let prayerZone = setting.zone;
                let prayerTimeForZone = parsed_data.processed.find(solat => solat.zone === prayerZone.toUpperCase());
                let prayerTimeToday = prayerTimeForZone.prayerTime[todayDay - 1];

                // console.log(prayerZone);

                // Set prayer zone to the UI
                const zoneElement = document.getElementById('zone');
                zoneElement.innerHTML = zones_db.find((zones) => zones.jakimCode == prayerZone.toUpperCase()).daerah;

                // Parse the epoch timestamp to Date object
                const prayers = {
                    "imsak": new Date(prayerTimeToday.fajr - 10 * 60 * 1000),
                    "subuh": new Date(prayerTimeToday.fajr * 1000),
                    "syuruk": new Date(prayerTimeToday.syuruk * 1000),
                    "dhuha": new Date(prayerTimeToday.syuruk + 28 * 60 * 1000),
                    "zuhur": new Date(prayerTimeToday.dhuhr * 1000),
                    "asar": new Date(prayerTimeToday.asr * 1000),
                    "maghrib": new Date(prayerTimeToday.maghrib * 1000),
                    "isyak": new Date(prayerTimeToday.isha * 1000),
                }

                console.table(prayers);

                // Modify a DOM element with the myData variable
                const subuhElement = document.getElementById('time-subuh');
                const zuhurElement = document.getElementById('time-zuhur');
                const asarElement = document.getElementById('time-asar');
                const maghribElement = document.getElementById('time-maghrib');
                const isyakElement = document.getElementById('time-isyak');

                const isHour12 = setting.time_format === "12";

                subuhElement.innerHTML = Intl.DateTimeFormat('en', { hour: 'numeric', minute: 'numeric', hour12: isHour12 }).format(prayers.subuh);
                zuhurElement.innerHTML = Intl.DateTimeFormat('en', { hour: 'numeric', minute: 'numeric', hour12: isHour12 }).format(prayers.zuhur);
                asarElement.innerHTML = Intl.DateTimeFormat('en', { hour: 'numeric', minute: 'numeric', hour12: isHour12 }).format(prayers.asar);
                maghribElement.innerHTML = Intl.DateTimeFormat('en', { hour: 'numeric', minute: 'numeric', hour12: isHour12 }).format(prayers.maghrib);
                isyakElement.innerHTML = Intl.DateTimeFormat('en', { hour: 'numeric', minute: 'numeric', hour12: isHour12 }).format(prayers.isyak);

                var x = setInterval(function () {

                    // get the current time
                    const now = new Date();
                    // month starts from 0
                    // const now = new Date(2023, 4, 4, 20, 39, 0); // for debugging

                    console.log(now);
                    console.log(prayers.subuh);

                    var lst1 = document.getElementsByClassName('imsak');
                    for (var i = 0; i < lst1.length; ++i) {
                        lst1[i].style.display = setting.other_prayer_times.imsak ? '' : 'none';
                    }

                    var lst2 = document.getElementsByClassName('syuruk');
                    for (var i = 0; i < lst2.length; ++i) {
                        lst2[i].style.display = setting.other_prayer_times.syuruk ? '' : 'none';
                    }

                    var lst3 = document.getElementsByClassName('dhuha');
                    for (var i = 0; i < lst3.length; ++i) {
                        lst3[i].style.display = setting.other_prayer_times.dhuha ? '' : 'none';
                    }

                    const upcomingPrayer = {};

                    // compare the current time with the prayer times
                    // red: when active prayer time
                    // blink: when time is in iqamah duration
                    if (now >= prayers.subuh && now < prayers.syuruk) {
                        subuhElement.style.color = 'red';
                        upcomingPrayer.name = "Syuruk"
                        upcomingPrayer.time = prayers.syuruk
                    } else if (now >= prayers.syuruk && now < prayers.zuhur) {
                        zuhurElement.style.color = 'red';
                        upcomingPrayer.name = "Zohor"
                        upcomingPrayer.time = prayers.zuhur
                    } else if (now >= prayers.zuhur && now < prayers.asar) {
                        zuhurElement.style.color = 'red';
                        upcomingPrayer.name = "Asar"
                        upcomingPrayer.time = prayers.asar
                    } else if (now >= prayers.asar && now < prayers.maghrib) {
                        asarElement.style.color = 'red';
                        upcomingPrayer.name = "Maghrib"
                        upcomingPrayer.time = prayers.maghrib
                    } else if (now >= prayers.maghrib && now < prayers.isyak) {
                        maghribElement.style.color = 'red';
                        upcomingPrayer.name = "Isyak"
                        upcomingPrayer.time = prayers.isyak
                    } else if (now >= prayers.isyak || now < prayers.subuh) {
                        isyakElement.style.color = 'red';
                        // it supposed to be the next waktu SUbuh
                        // but the difference is neglibgle
                        upcomingPrayer.name = "Subuh"
                        upcomingPrayer.time = prayers.subuh
                    }

                    // set countdown
                    // Set the date we're counting down to
                    console.log('upcomingPrayer');
                    console.log(upcomingPrayer);
                    var countDownDate = upcomingPrayer.time.getTime();

                    // Update the countdown every 1 second
                    // Get today's date and time
                    var nowTime = now.getTime();

                    // Find the distance between now and the countdown date
                    var distance = countDownDate - nowTime;

                    // Calculate the days, hours, minutes and seconds remaining
                    var days = Math.floor(distance / (1000 * 60 * 60 * 24));
                    var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                    var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                    var seconds = Math.floor((distance % (1000 * 60)) / 1000);

                    // Output the result in an element with id="countdown"
                    document.getElementById("countdown").innerHTML = upcomingPrayer.name + ": -" + hours + "h "
                        + minutes + "m " + seconds + "s ";

                    // If the countdown is over, write some text
                    if (distance < 0) {
                        clearInterval(x);
                        document.getElementById("countdown").innerHTML = "Subuh (Tomorrow)";
                    }
                }, 1000);
            })
            .catch(error => {
                // Handle any errors that occur
                console.error(error);
            });
    })
    .catch(error => {
        // Handle any errors that occur
        console.error(error);
    });

refreshAt(0, 0, 0) // refresh during midnight

function refreshAt(hours, minutes, seconds) {
    var now = new Date();
    var then = new Date();

    if (now.getHours() > hours ||
        (now.getHours() == hours && now.getMinutes() > minutes) ||
        now.getHours() == hours && now.getMinutes() == minutes && now.getSeconds() >= seconds) {
        then.setDate(now.getDate() + 1);
    }
    then.setHours(hours);
    then.setMinutes(minutes);
    then.setSeconds(seconds);

    var timeout = (then.getTime() - now.getTime());
    setTimeout(function () { window.location.reload(true); }, timeout);
}