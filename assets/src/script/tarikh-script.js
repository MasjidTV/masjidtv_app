// Get today date
const today = new Date();
let todayDay = today.getDate();

fetch('../../config.json')
    .then(response => response.json())
    .then(setting => {
        fetch('../../db/May-2023.processed.json')
            .then(response => response.json())
            .then(parsed_data => {
                let prayerTimeForZone = parsed_data.processed.find(solat => solat.zone === 'SGR01');
                let prayerTimeToday = prayerTimeForZone.prayerTime[todayDay - 1];
                const hijriDate = prayerTimeToday.hijri;
                const [year, month, day] = hijriDate.split('-').map(Number);
                var dateHijri = umalqura(year, month, day).format('longDate');

                // set date
                const dateElement = document.getElementById('tarikh-miladi');
                dateElement.innerHTML = Intl.DateTimeFormat(setting.tarikh.locale, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }).format(today);

                const dateElement2 = document.getElementById('tarikh-hijri');
                dateElement2.innerHTML = dateHijri
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