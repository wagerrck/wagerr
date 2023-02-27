#!/usr/bin/env python3
# Copyright (c) 2018-2021 The Wagerr Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

from test_framework.test_framework import WagerrTestFramework
from test_framework.util import connect_nodes, wait_until

'''
'''

class SporkTest(WagerrTestFramework):
    def set_test_params(self):
        self.num_nodes = 3
        self.setup_clean_chain = True
        self.extra_args = [["-sporkkey=6xLZdACFRA53uyxz8gKDLcgVrm5kUUEu2B3BUzWUxHqa2W7irbH"], [], []]

    def setup_network(self):
        self.disable_mocktime()
        self.setup_nodes()
        # connect only 2 first nodes at start
        connect_nodes(self.nodes[0], 1)

    def get_test_spork_state(self, node):
        info = node.spork('active')
        # use InstantSend spork for tests
        return info['SPORK_2_INSTANTSEND_ENABLED']

    def set_test_spork_state(self, node, state):
        if state:
            value = 0
        else:
            value = 4070908800
        # use InstantSend spork for tests
        node.sporkupdate("SPORK_2_INSTANTSEND_ENABLED", value)

    def run_test(self):
        spork_default_state = self.get_test_spork_state(self.nodes[0])
        # check test spork default state matches on all nodes
        assert self.get_test_spork_state(self.nodes[1]) == spork_default_state
        assert self.get_test_spork_state(self.nodes[2]) == spork_default_state

        # check spork propagation for connected nodes
        spork_new_state = not spork_default_state
        self.set_test_spork_state(self.nodes[0], spork_new_state)
        wait_until(lambda: self.get_test_spork_state(self.nodes[1]), sleep=0.2, timeout=60)

        # restart nodes to check spork persistence
        self.stop_node(0)
        self.stop_node(1)
        self.start_node(0)
        self.start_node(1)
        assert self.get_test_spork_state(self.nodes[0]) == spork_new_state
        assert self.get_test_spork_state(self.nodes[1]) == spork_new_state

        # Generate one block to kick off masternode sync, which also starts sporks syncing for node2
        self.nodes[1].generate(1)

        # connect new node and check spork propagation after restoring from cache
        connect_nodes(self.nodes[1], 2)
        wait_until(lambda: self.get_test_spork_state(self.nodes[2]), sleep=0.1, timeout=10)

if __name__ == '__main__':
    SporkTest().main()
