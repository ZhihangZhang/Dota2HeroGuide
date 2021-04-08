import requests
from bs4 import BeautifulSoup
import pprint
import json

pp = pprint.PrettyPrinter(indent=4)
def scrape_heros():
    heros = []
    counters = set()
    synergies = set()

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
        c, s = scrape_counters_and_synergies(h['name'], h['url'])
        counters = counters | c
        synergies = synergies | s

    # pp.pprint(heros)
    # pp.pprint(counters)
    # pp.pprint(synergies)
    return (heros, counters, synergies)


def scrape_counters_and_synergies(name, url):
    counters = set()
    synergies = set()

    full_url = url + '/Counters'
    page = requests.get(full_url)
    soup = BeautifulSoup(page.content, 'html.parser')

    ba = soup.select('span[id*="Bad_against..."]')[0]
    siblings = ba.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            other = standardize(c.get_text())
            counters.add((other, name))

        if s.name == 'h2' or s.name == 'p' or s.name == 'h3' :
            break

    ga = soup.select('span[id*="Good_against..."]')[0]
    siblings = ga.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            other = standardize(c.get_text())
            counters.add((name, other))

        if s.name == 'h2' or s.name == 'p' or s.name == 'h3' :
            break

    www = soup.select('span[id*="Works_well_with..."]')[0]
    siblings = www.parent.findNextSiblings()
    for s in siblings:
        cs = s.select('b a')
        for c in cs:
            other = standardize(c.get_text())
            # synergy is commutative
            synergies.add((name, other))
            synergies.add((other, name))
        if s.name == 'h2' or s.name == 'p' or s.name == 'h3' :
            break

    # pp.pprint(counters)
    # pp.pprint(synergies)
    return (counters, synergies)

def standardize(name):
    return name.replace(' ', '_').replace("'", '').lower()

def generate_prolog(heros, counters, synergies):
    # heros
    with open('heros.pl', 'w') as outfile:
        for h in heros:
            name = h['name']
            line = f'prop({name}, type, hero).\n'
            outfile.write(line)

    # counters and synergies
    with open('counters_and_synergies.pl', 'w') as outfile:
        outfile.write('% Counters\n')
        for c in sorted(counters):
            line = f'prop({c[0]}, counters, {c[1]}).\n'
            outfile.write(line)

        outfile.write('\n')

        outfile.write('% Synergies\n')
        for s in sorted(synergies):
            line = f'prop({s[0]}, synergizes, {s[1]}).\n'
            outfile.write(line)

if __name__ == '__main__':
    # test_url = 'https://dota2.fandom.com/wiki/Grimstroke'
    # scrape_counters_and_synergies("grimstroke", test_url)
    heros, counters, synergies = scrape_heros()
    generate_prolog(heros, counters, synergies)

