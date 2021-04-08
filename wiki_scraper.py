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
        c, s = scrape_counters_and_synergies(h['url'])
        h['counters'] = c
        h['synergies'] = s

    return heros


def scrape_counters_and_synergies(url):
    counters = []
    synergies = []
    full_url = url + '/Counters'
    page = requests.get(full_url)
    soup = BeautifulSoup(page.content, 'html.parser')

    counter_heading = soup.select('span[id*="Good_against..."]')[0]
    siblings = counter_heading.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            counters.append(standardize(c.get_text()))
        if s.name == 'h2' or s.name == 'p' or s.name == 'h3' :
            break

    synergy_heading = soup.select('span[id*="Works_well_with..."]')[0]
    siblings = synergy_heading.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            synergies.append(standardize(c.get_text()))
        if s.name == 'h2' or s.name == 'p' or s.name == 'h3' :
            break

    # pp.pprint(counters)
    # pp.pprint(synergies)
    return (counters, synergies)

def standardize(name):
    return name.replace(' ', '_').replace("'", '').lower()

def generate_prolog(heros):
    # heros
    with open('heros.pl', 'w') as outfile:
        for h in heros:
            name = h['name']
            line = f'prop({name}, type, hero).\n'
            outfile.write(line)

    # counters and synergies
    with open('counters_and_synergies.pl', 'w') as outfile:
        for h in heros:
            name = h['name']
            outfile.write(f'% {name}\n')
            for c in h['counters']:
                line = f'prop({name}, counters, {c}).\n'
                outfile.write(line)
            for c in h['synergies']:
                line = f'prop({name}, synergizes, {c}).\n'
                outfile.write(line)
            outfile.write('\n')

if __name__ == '__main__':
    # test_url = 'https://dota2.fandom.com/wiki/Grimstroke'
    # scrape_counters_and_synergies(test_url)
    heros = scrape_heros()

    # dump as json
    with open('heros.json', 'w') as outfile:
        json.dump(heros, outfile, indent=4)

    generate_prolog(heros)

