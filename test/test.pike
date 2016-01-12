
int main(int argc, array(string) argv)
{
  WS.wsarray res = .TestModule.get_cities_by_country("sweden");

  foreach (res, WS.wsmap city) {
    write("* %s, %s\n", city->city, city->country);

    if (city->city == "Norrkoping") {
      WS.wsmap weather;
      weather = .TestModule.get_weather_by_city(city->city, city->country);
      write("%O\n", weather);
    }
  }

  return 0;
}
