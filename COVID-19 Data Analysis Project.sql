-- 1.
-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in the United States
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%'
	AND continent IS NOT NULL
ORDER BY location, date;

-- 2.
-- Looking at Total Cases vs Population
-- Shows what percentage of population contracted COVID by country per day
SELECT
	location,
	population,
	date,
	total_cases, (total_cases/population)*100 AS Population_Infected_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location, date;

-- 3.
-- Looking at countries with highest infection rate compared to population
SELECT
	location,
	population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS Population_Infected_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Population_Infected_Percentage DESC;

-- 4.
-- Showing countries with the highest death count per population
SELECT
	location,
	MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_Death_Count DESC;


-- 5.
-- Comparing daily death count, vaccinations, and cases in each country
SELECT
	cd.location,
	population,
	cd.date,
	total_cases,
	(total_cases/population)*100 AS Population_Infected_Percentage,
	total_deaths,
	people_vaccinated,
	people_fully_vaccinated,
	new_cases,
	new_deaths,
	new_vaccinations,
	total_vaccinations
FROM PortfolioProject..CovidDeaths$ AS cd
LEFT JOIN CovidVaccinations$ AS cv
ON cd.location = cv.location AND
cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;

-- Continent Breakdown

-- 6.
-- Showing continent with highest deaths per population
SELECT
	continent,
	MAX(CAST(total_deaths AS INT)) AS Highest_Death_Count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highest_Death_Count DESC;

-- 7.
-- Showing total death per continent
WITH CTE AS (
SELECT continent, location, MAX(CAST(total_deaths AS INT)) AS Total_deaths
FROM PortfolioProject..CovidDeaths$
GROUP BY location, continent
)
SELECT continent, SUM(Total_deaths) AS Total_Deaths_Continent
FROM CTE
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Deaths_Continent DESC;


-- Global Stats

-- 8.
-- Showing new daily cases, new daily deaths, daily death percentage on a global scale
SELECT
	date,
	SUM(new_cases) AS New_Daily_Cases,
	SUM(CAST(new_deaths AS INT)) AS New_Daily_Deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- 9.
-- Showing total global cases, deaths, and death percentage
SELECT
	SUM(new_cases) AS Total_Global_Cases,
	SUM(CAST(new_deaths AS INT)) AS Total_Global_Deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Total_Global_Death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL;

-- 10.
-- Comparing total population and population vaccinated
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Population_Vaccinated
FROM PortfolioProject..CovidVaccinations$ AS v
JOIN PortfolioProject..CovidDeaths$ AS d
	ON v.date = d.date
	AND v.location = d.location
WHERE d.continent IS NOT NULL
ORDER BY 2, 3;


-- 11.
-- Show percentage of vaccinated population for each country country 

-- Method 1: Using CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Population_Vaccinated)
AS
(
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Population_Vaccinated
FROM PortfolioProject..CovidVaccinations$ AS v
JOIN PortfolioProject..CovidDeaths$ AS d
	ON v.date = d.date
	AND v.location = d.location
WHERE d.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (Rolling_Population_Vaccinated/Population)*100 AS Population_Vaccinated_Percent
FROM PopVsVac
ORDER BY Location, Date;


-- Method 2: Using Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
Rolling_Population_Vaccinated NUMERIC
)

INSERT INTO PercentPopulationVaccinated
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Population_Vaccinated
FROM PortfolioProject..CovidVaccinations$ AS v
JOIN PortfolioProject..CovidDeaths$ AS d
	ON v.date = d.date
	AND v.location = d.location
WHERE d.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (Rolling_Population_Vaccinated/Population)*100 AS Population_Vaccinated_Percent
FROM PercentPopulationVaccinated
ORDER BY Location, Date;

-- 12.
-- Creating View to store data for visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated_View;
CREATE VIEW PercentPopulationVaccinated_View AS
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_Population_Vaccinated
FROM PortfolioProject..CovidVaccinations$ AS v
JOIN PortfolioProject..CovidDeaths$ AS d
	ON v.date = d.date
	AND v.location = d.location
WHERE d.continent IS NOT NULL;
--ORDER BY 2, 3


-- Check all existing views
SELECT *
FROM INFORMATION_SCHEMA.Views
WHERE TABLE_NAME != 'spt_values';