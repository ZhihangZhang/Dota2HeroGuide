import requests
from bs4 import BeautifulSoup
import pprint
import json

pp = pprint.PrettyPrinter(indent=4)
def scrape_heros():
    heros = []
    base_url = 'https://dota2.fandom.com'
    full_url = base_url + '/wiki/Hero_Grid'
    page = requests.get(full_url)
    soup = BeautifulSoup(page.content, 'html.parser')

    # scrape hero texts and urls
    divs = soup.select('div.heroentry')
    for d in divs:
        h = {
            'name': standardize(d.select('div.heroentrytext')[0].get_text()),
            'url': base_url + d.select('div a')[0]['href']
        }
        heros.append(h)

    # scrape heros that a hero counters or synergizes with
    for h in heros:
        c, s = scrape_counters_and_synergy(h['url'])
        h['counters'] = c
        h['synergy'] = s

    with open('heros.json', 'w') as outfile:
        json.dump(heros, outfile, indent=4)


def scrape_counters_and_synergy(url):
    counters = []
    synergy = []
    full_url = url + '/Counters'
    page = requests.get(full_url)
    soup = BeautifulSoup(page.content, 'html.parser')

    counter_heading = soup.select('span[id*="Good_against..."]')[0]
    siblings = counter_heading.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            counters.append(standardize(c.get_text()))
        if s.name == 'h2' or s.name == 'p':
            break

    synergy_heading = soup.select('span[id*="Works_well_with..."]')[0]
    siblings = synergy_heading.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            synergy.append(standardize(c.get_text()))
        if s.name == 'h2' or s.name == 'p':
            break

    # pp.pprint(counters)
    # pp.pprint(synergy)
    return (counters, synergy)

def standardize(name):
    return name.replace(' ', '_').lower()

if __name__ == '__main__':
    # test_url = 'https://dota2.fandom.com/wiki/Grimstroke'
    scrape_heros()
    # scrape_counters_and_synergy(test_url)
