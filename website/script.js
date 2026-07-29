const grantPanel = document.querySelector('[data-grant-panel]');
const searchForm = document.querySelector('[data-search-form]');
const loadingPanel = document.querySelector('[data-loading-panel]');
const weatherPanel = document.querySelector('[data-weather-panel]');
const errorPanel = document.querySelector('[data-error-panel]');
const searchInput = document.querySelector('[data-search-input]');
const grantAccessButton = document.querySelector('[data-grant-access]');
const fadeElements = document.querySelectorAll('.fade-up');

const API_KEY = 'd1845658f92b31c64bd94f06f7188c9c';

function showError(message) {
  errorPanel.textContent = message;
  errorPanel.classList.add('active');
}

function clearError() {
  errorPanel.textContent = '';
  errorPanel.classList.remove('active');
}

function toggleLoading(isLoading) {
  if (isLoading) {
    loadingPanel.classList.add('active');
    weatherPanel.classList.remove('active');
    grantPanel.classList.remove('active');
    searchForm.classList.remove('active');
  } else {
    loadingPanel.classList.remove('active');
  }
}

function getFromSessionStorage() {
  const storedCoordinates = sessionStorage.getItem('user-coordinates');
  if (!storedCoordinates) {
    grantPanel.classList.add('active');
    weatherPanel.classList.remove('active');
    searchForm.classList.remove('active');
    return;
  }

  const coordinates = JSON.parse(storedCoordinates);
  fetchWeatherInfo(coordinates);
}

async function fetchWeatherInfo(coordinates) {
  const { lat, lon } = coordinates;
  clearError();
  toggleLoading(true);

  try {
    const response = await fetch(`https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${API_KEY}&units=metric`);
    const data = await response.json();

    if (!response.ok || data.cod !== 200) {
      throw new Error(data.message || 'Unable to fetch weather data.');
    }

    renderWeatherInfo(data);
    weatherPanel.classList.add('active');
  } catch (error) {
    showError(error.message || 'Weather request failed.');
  } finally {
    toggleLoading(false);
  }
}

async function fetchSearchWeatherInfo(city) {
  if (!city) return;
  clearError();
  toggleLoading(true);

  try {
    const response = await fetch(`https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${API_KEY}&units=metric`);
    const data = await response.json();

    if (!response.ok || data.cod !== 200) {
      throw new Error(data.message || 'City not found.');
    }

    renderWeatherInfo(data);
    weatherPanel.classList.add('active');
  } catch (error) {
    showError(error.message || 'Search request failed.');
  } finally {
    toggleLoading(false);
  }
}

function renderWeatherInfo(weatherInfo) {
  const cityName = document.querySelector('[data-city-name]');
  const countryIcon = document.querySelector('[data-country-icon]');
  const desc = document.querySelector('[data-weather-desc]');
  const weatherIcon = document.querySelector('[data-weather-icon]');
  const temp = document.querySelector('[data-temp]');
  const windspeed = document.querySelector('[data-windspeed]');
  const humidity = document.querySelector('[data-humidity]');
  const cloudiness = document.querySelector('[data-cloudiness]');

  cityName.textContent = weatherInfo.name || 'Unknown location';
  countryIcon.src = `https://flagcdn.com/144x108/${weatherInfo.sys.country.toLowerCase()}.png`;
  countryIcon.alt = `${weatherInfo.sys.country} flag`;
  desc.textContent = weatherInfo.weather?.[0]?.description || 'Clear skies';
  weatherIcon.src = `https://openweathermap.org/img/wn/${weatherInfo.weather?.[0]?.icon}@2x.png`;
  weatherIcon.alt = weatherInfo.weather?.[0]?.description || 'Weather icon';
  temp.textContent = `${Math.round(weatherInfo.main.temp)}°C`;
  windspeed.textContent = `${weatherInfo.wind.speed} m/s`;
  humidity.textContent = `${weatherInfo.main.humidity}%`;
  cloudiness.textContent = `${weatherInfo.clouds.all}%`;
}

function setLocation(position) {
  const userCoordinates = {
    lat: position.coords.latitude,
    lon: position.coords.longitude,
  };

  sessionStorage.setItem('user-coordinates', JSON.stringify(userCoordinates));
  fetchWeatherInfo(userCoordinates);
}

function requestLocationAccess() {
  if (!navigator.geolocation) {
    showError('Geolocation is not supported by this browser.');
    return;
  }

  navigator.geolocation.getCurrentPosition(setLocation, () => {
    showError('Location access denied. Please search by city instead.');
  });
}

if (grantAccessButton) {
  grantAccessButton.addEventListener('click', requestLocationAccess);
}

if (searchForm) {
  searchForm.addEventListener('submit', (event) => {
    event.preventDefault();
    const city = searchInput.value.trim();
    if (!city) return;
    fetchSearchWeatherInfo(city);
  });
}

window.addEventListener('load', () => {
  document.body.classList.add('js-enabled');
  fadeElements.forEach((element, index) => {
    window.setTimeout(() => element.classList.add('visible'), index * 120);
  });
  getFromSessionStorage();
});
